#!/bin/bash

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

cat << EOF > /tmp/bookinf_role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: bookinfo
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["list", "get", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get"]
EOF

kubectl create -f /tmp/bookinf_role.yaml

kubectl create rolebinding --namespace=default bookinfo-binding --role=bookinfo --serviceaccount=default:default