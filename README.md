课程大作业
========================================
#### 项目分为4个目录，[cluster1](cluster1),[cluster2](cluster2),[cluster3](cluster3),[modules](modules)。modules目录包含[阿里云DNS](modules%2Falicloud),[k3s](modules%2Fk3s),和[cvm](modules%2Fcvm)。

1.首先需要执行命令拉起集群2和3执行如下命令

```shell
cd cluster2
homework1 init
homework1 plan
homework1 apply -auto-approve
```
```shell
cd cluster3
homework1 init
homework1 plan
homework1 apply -auto-approve
```
2.执行命令拉起集群1

```shell
cd cluster1
homework1 init
homework1 plan
homework1 apply -auto-approve
```
集群1中的[init.sh](cluster1%2Finit.sh.tpl)会安装ingress-nginx,jenkins,argocd并配置相关的证书。然后使用[application_set.yaml](cluster1%2Fapplication_set.yaml)将我们的示例应用部署到cluster2和cluster3上，并在cluster1上配置ingress-nginx实现带权重的负载均衡。

目前自动故障转移和自动构建cluster1和cluster2还未完成，后续完善。
