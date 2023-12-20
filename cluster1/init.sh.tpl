#!/bin/bash

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

#install helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

sleep 5s
#install ingress-nginx
#https://kubernetes.github.io/ingress-nginx/user-guide/basic-usage/
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
kubectl wait --for=condition=Ready pod --all -n ingress-nginx --timeout=300s

sleep 5s
#install cert-manager
#https://cert-manager.io/docs/tutorials/acme/nginx-ingress/
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.1 \
  --set installCRDs=true
kubectl apply -f https://raw.githubusercontent.com/pragkent/alidns-webhook/master/deploy/bundle.yaml
cat <<EOF | sudo tee /tmp/ali-clusterIssuer-prd.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alidns-secret
  namespace: cert-manager
data:
  access-key: ${alidns_access_key}
  secret-key: ${alidns_secret_key}
EOF
cat <<EOF | sudo tee /tmp/alidns-secret.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prd
spec:
  acme:
    # Change to your letsencrypt email
    email: ${acme_email}
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prd-account-key
    solvers:
    - dns01:
        webhook:
          groupName: acme.yourcompany.com
          solverName: alidns
          config:
            region: ""
            accessKeySecretRef:
              name: alidns-secret
              key: access-key
            secretKeySecretRef:
              name: alidns-secret
              key: secret-key
EOF
kubectl apply -f /tmp/alidns-secret.yaml -n cert-manager
kubectl apply -f /tmp/ali-clusterIssuer-prd.yaml -n cert-manager
cat << EOF > /tmp/ali-certificate-prd.yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: wjmcloud-top-tls
spec:
  secretName: wjmcloud-top-tls
  commonName:
  dnsNames:
  - "*.${domain}"
  issuerRef:
    name: letsencrypt-prd
    kind: ClusterIssuer
EOF

sleep 5s
#install argocd
#https://artifacthub.io/packages/helm/argo/argo-cd?modal=install
#https://itnext.io/helm-chart-install-advanced-usage-of-the-set-argument-3e214b69c87a
kubectl create ns argocd
sed -i "s/  - .*$/  - ${domain_prefix}.argocd.${domain}/g" /tmp/ali-certificate-prd.yaml
kubectl apply -f /tmp/ali-certificate-prd.yaml -n argocd
cat << EOF > /tmp/argocd-values.yaml
configs:
  params:
    server.insecure: true
server:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - "${domain_prefix}.argocd.${domain}"
    tls:
      - secretName: "wjmcloud-top-tls"
        hosts:
          - "${domain_prefix}.argocd.${domain}"
EOF
helm repo add argo https://argoproj.github.io/argo-helm
helm upgrade --install argocd argo/argo-cd -n argocd \
 -f /tmp/argocd-values.yaml \
 --version 5.46.8

#install applicationset
kubectl apply -f https://raw.githubusercontent.com/argoproj/applicationset/v0.4.0/manifests/install.yaml -n argocd

#Install argocd cli and log in
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

sleep 60s
argocd login ${domain_prefix}.argocd.${domain} --skip-test-tls --grpc-web --username admin --password `kubectl get secret argocd-initial-admin-secret -n argocd -oyaml | grep password | awk -F " " '{print $2}' | base64 -d`

#add cluster2,cluster3
argocd cluster add -y --kubeconfig /tmp/cluster2.yaml cluster2
argocd cluster add -y --kubeconfig /tmp/cluster3.yaml cluster3

#install applicationSet
kubectl apply -f /tmp/application_set.yaml -n argocd

sleep 5s
#install jenkins
#https://www.jenkins.io/doc/book/installing/kubernetes/
helm repo add jenkins https://charts.jenkins.io
kubectl create namespace jenkins
cat <<EOF | sudo tee /tmp/jenkins-sa.yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: jenkins
  namespace: jenkins
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: jenkins
rules:
- apiGroups:
  - '*'
  resources:
  - statefulsets
  - services
  - replicationcontrollers
  - replicasets
  - podtemplates
  - podsecuritypolicies
  - pods
  - pods/log
  - pods/exec
  - podpreset
  - poddisruptionbudget
  - persistentvolumes
  - persistentvolumeclaims
  - jobs
  - endpoints
  - deployments
  - deployments/scale
  - daemonsets
  - cronjobs
  - configmaps
  - namespaces
  - events
  - secrets
  verbs:
  - create
  - get
  - watch
  - delete
  - list
  - patch
  - update
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
  - list
  - watch
  - update
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: jenkins
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: jenkins
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:serviceaccounts:jenkins
EOF
sed -i "s/  - .*$/  - ${domain_prefix}.jenkins.${domain}/g" /tmp/ali-certificate-prd.yaml
kubectl apply -f /tmp/jenkins-sa.yaml,/tmp/ali-certificate-prd.yaml -n jenkins
cat <<EOF | sudo tee /tmp/jenkins-values.yaml
agent:
  resources:
    requests:
      cpu: "512m"
      memory: "512Mi"
    limits:
      cpu: "2000m"
      memory: "2048Mi"
serviceAccount:
  create: false
controller:
  ingress:
    enabled: true
    hostName: "${domain_prefix}.jenkins.${domain}"
    ingressClassName: nginx
    tls:
      - secretName: "wjmcloud-top-tls"
        hosts:
          - "${domain_prefix}.jenkins.${domain}"
  installPlugins:
    - kubernetes:4029.v5712230ccb_f8
    - workflow-aggregator:596.v8c21c963d92d
    - git:5.1.0
    - configuration-as-code:1670.v564dc8b_982d0
  additionalPlugins:
    - prometheus:2.2.3
    - kubernetes-credentials-provider:1.211.vc236a_f5a_2f3c
    - job-dsl:1.84
    - github:1.37.1
    - github-branch-source:1725.vd391eef681a_e
    - gitlab-branch-source:660.vd45c0f4c0042
    - gitlab-kubernetes-credentials:132.v23fd732822dc
    - pipeline-stage-view:2.33
    - sonar:2.15
    - pipeline-utility-steps:2.16.0
EOF
helm install jenkins jenkins/jenkins -n jenkins  -f /tmp/jenkins-values.yaml
# get admin pwd
# kubectl exec --namespace jenkins -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
cat <<EOF | sudo tee /tmp/jenkins_pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 10Gi
EOF
kubectl apply -f /tmp/jenkins_pvc.yaml -n jenkins

#https://faun.pub/use-of-endpoints-in-kubernetes-18b0346de6d1
#https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm
#https://nginx.org/en/docs/http/load_balancing.html#nginx_weighted_load_balancing
#install nginx
kubectl create namespace bookinfo
cat <<EOF | sudo tee /tmp/nginx.conf
# /etc/nginx/nginx.conf

events {}         # event context have to be defined to consider config valid

http {
    upstream ${domain_prefix}.bookinfo.${domain} {
        server `argocd cluster list  | grep cluster2  | awk -F "//" '{print $2}' | awk -F ":" '{print $1}'`:9080 weight=5;
        server `argocd cluster list  | grep cluster3  | awk -F "//" '{print $2}' | awk -F ":" '{print $1}'`:9080;
    }

    server {
        listen 80;

        location / {
            proxy_pass http://${domain_prefix}.bookinfo.${domain};
        }
    }
}
EOF
kubectl create configmap nginx-conf --from-file=/tmp/nginx.conf -n bookinfo

cat <<EOF | sudo tee /tmp/nginx_bookinfo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
          volumeMounts:
            - name: nginx-conf
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
          ports:
            - containerPort: 80
      volumes:
        - name: nginx-conf
          configMap:
            name: nginx-conf

---

apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80

---

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bookinfo-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: ${domain_prefix}.bookinfo.${domain}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-service
                port:
                  number: 80
EOF
kubectl apply -f /tmp/nginx_bookinfo.yaml -n bookinfo
