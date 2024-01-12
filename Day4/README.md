# Day 4 - Provision a simple app on a set of Kubernetes clusters using Config Sync, kpt and porch

## Introduction

This is demo takes everything we learned in the prior days and moves us closer to a real world scenario where we will deploy apps on a fleet of Kubernetes clusters.  
To achive this we will mimick a set of workload Kubernetes clusters using [kind](https://kind.sigs.k8s.io/).  
The avid reader will have noticed that we already ran all the prior demos on a ```kind``` cluster. We will still keep going with the pattern of that initial ```kind``` cluster but designate it as the control plane cluster.

For our convenience both the ```gitea``` and the ```kind``` containers are already up and running fully provisioned with the foundational tooling to run the demo code below. 

![Configuration as Data Day4](/images/nephio_cad_day4.png)  
  
## Instructions

#### 1. Build the demo environment Docker image and then run it
We build the Docker image from to the [Dockerfile](./Dockerfile) in the current directory.

```
docker build -t workstation:day4 .

docker run --rm -d --env='DOCKER_OPTS=' --volume=/var/lib/docker --privileged \
           --name demo -p 8080:80 -p 3000:3000 -p 7007:7007 workstation:day4
```

#### 2. Follow the boot/demo logs
When starting the demo container image it will set up the demo environment for you.  

Depending on the spec of your hardware setup this might take a bit of time.

You can tail the logs to follow the progress of the demo boot/install process.
Run the command below and wait for the log entry reading ```Startup complete```.

```
docker logs -f demo
...


-----------------
demo installation done
-----------------
Startup complete
```

#### 3. Connect to the demo environment
Connect to the Workstation by pointing your browser to [http://localhost:8080](http://localhost:8080).
Then open a [Terminal window](../README.md#Instructions) to execute the commands below.


#### 4. Inspect the demo environmnent setup
Let's have a quick look at the pre-configured setup.  
* Both the ```gitea``` and ```kind``` containers are running

Note that you can also access the ```gitea``` repo by pointing your browser to [http://localhost:3000](http://localhost:3000). Use ```demo/demo``` to login to the gitea repository server.

```
docker ps
# The output should look something like the below
# d69487aeb0fc  kindest/node:v1.25.3         2 minutes ago  127.0.0.1:34593->6443/tcp                       demo-control-plane
# 7f9086f6184f  gitea/gitea:1.17.3-rootless  3 minutes ago  0.0.0.0:2222->2222/tcp, 0.0.0.0:3000->3000/tcp  gitea

kubectl get nodes
# The output should look something like the below
# NAME                 STATUS   ROLES           AGE   VERSION
# demo-control-plane   Ready    control-plane   26s   v1.25.3

kubectl get pods --all-namespaces
# The output should look something like the below
# NAMESPACE                           NAME                                                             READY   STATUS    RESTARTS   AGE
# backstage-ui-plugin                 backstage-5755fdd99f-ntb28                                       1/1     Running   0          2m5s
# capd-system                         capd-controller-manager-d66fcc66d-sldbw                          1/1     Running   0          12m
# capi-kubeadm-bootstrap-system       capi-kubeadm-bootstrap-controller-manager-5bbc77f45f-9csv7       1/1     Running   0          12m
# capi-kubeadm-control-plane-system   capi-kubeadm-control-plane-controller-manager-6f8f8d7477-jbqcz   1/1     Running   0          12m
# capi-system                         capi-controller-manager-67969565f5-nm99g                         1/1     Running   0          12m
# cert-manager                        cert-manager-5b8f9b9d96-rcg7s                                    1/1     Running   0          13m
# cert-manager                        cert-manager-cainjector-54f68bfb64-vfpdp                         1/1     Running   0          13m
# cert-manager                        cert-manager-webhook-f6c8487d6-5scdr                             1/1     Running   0          13m
# config-management-monitoring        otel-collector-659876667-xx75c                                   1/1     Running   0          10m
# config-management-system            config-management-operator-58ff7dbd66-s6sng                      1/1     Running   0          12m
# config-management-system            reconciler-manager-679c4ccc96-7cd8v                              2/2     Running   0          10m
# config-management-system            root-reconciler-demo-root-sync-7db777b4bc-nzmd5                  4/4     Running   0          8m44s
# kube-system                         coredns-565d847f94-7hj2d                                         1/1     Running   0          13m
# kube-system                         coredns-565d847f94-x28vw                                         1/1     Running   0          13m
# kube-system                         etcd-demo-control-plane                                          1/1     Running   0          13m
# kube-system                         kindnet-cjg85                                                    1/1     Running   0          13m
# kube-system                         kube-apiserver-demo-control-plane                                1/1     Running   0          13m
# kube-system                         kube-controller-manager-demo-control-plane                       1/1     Running   0          13m
# kube-system                         kube-proxy-bvh4v                                                 1/1     Running   0          13m
# kube-system                         kube-scheduler-demo-control-plane                                1/1     Running   0          13m
# local-path-storage                  local-path-provisioner-684f458cdd-p7p29                          1/1     Running   0          13m
# porch-fn-system                     apply-replacements-85913d4e                                      1/1     Running   0          11m
# porch-fn-system                     apply-setters-4d429572                                           1/1     Running   0          11m
# porch-fn-system                     create-setters-0220cc87                                          1/1     Running   0          11m
# porch-fn-system                     enable-gcp-services-a56558d5                                     1/1     Running   0          11m
# porch-fn-system                     ensure-name-substring-33ff7d9a                                   1/1     Running   0          11m
# porch-fn-system                     export-terraform-571fedd3                                        1/1     Running   0          11m
# porch-fn-system                     gatekeeper-a1c19318                                              1/1     Running   0          11m
# porch-fn-system                     generate-folders-4511c517                                        1/1     Running   0          11m
# porch-fn-system                     kubeval-bb88cbcc                                                 1/1     Running   0          11m
# porch-fn-system                     remove-local-config-resources-2825914e                           1/1     Running   0          11m
# porch-fn-system                     search-replace-6864b06b                                          1/1     Running   0          11m
# porch-fn-system                     set-annotations-76d65ebd                                         1/1     Running   0          11m
# porch-fn-system                     set-enforcement-action-aea09be3                                  1/1     Running   0          11m
# porch-fn-system                     set-image-49c7a466                                               1/1     Running   0          11m
# porch-fn-system                     set-labels-0dfc3c8a                                              1/1     Running   0          11m
# porch-fn-system                     set-namespace-f930d924                                           1/1     Running   0          11m
# porch-fn-system                     set-project-id-966c9e51                                          1/1     Running   0          11m
# porch-fn-system                     starlark-6ba3971c                                                1/1     Running   0          11m
# porch-fn-system                     upsert-resource-77196bdb                                         1/1     Running   0          11m
# porch-system                        function-runner-6ff7ff6744-dbk64                                 1/1     Running   0          12m
# porch-system                        function-runner-6ff7ff6744-dsnj2                                 1/1     Running   0          12m
# porch-system                        porch-controllers-5467dfd9c7-nz5lp                               1/1     Running   0          12m
# porch-system                        porch-server-656c6fb555-btt5d                                    1/1     Running   0          12m
# resource-group-system               resource-group-controller-manager-795b9cb9c-kbfpw                2/2     Running   0          10m
```

#### 5. Connect to the porch backstage UI 
To be able to connect to the porch backstage UI we need to port forward the service where porch is exposed to in the cluster.   
You can do so by running the command below.   
```
kubectl port-forward  service/backstage 7007:7007 --address='0.0.0.0' -n backstage-ui-plugin
```
Connect to the [porch backstage UI](http://localhost:7007) by pointing your browser to [http://localhost:7007/config-as-data](http://localhost:7007/config-as-data).   
You can now explore the porch resources through the backstage UI.

#### 6. Configure git with the base config

Let's configure ```git``` with the base config items it expects to run properly (note we totally make up these config values). 

```
git config --global user.email "demo@d.com"
git config --global user.name "demo"
```

#### 7. Create a demo-cluster repo

```
export TOKEN=$(cat /demo/giteatoken)
curl -k -H "Authorization: token $TOKEN" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d '{"auto_init": true, "name": "demo-cluster"}' \
     http://localhost:3000/api/v1/user/repos
```

#### 8. Create and pull the cluster configuration kpt package 

We create a simple package called ```day4-demo-cluster```.

```
kpt alpha rpkg init day4-demo-cluster --namespace=default --repository=day4 --workspace=v1
kpt alpha rpkg pull day4-c33e8e702e5c39ba6099bc7c57d202f9d1d87d6c -ndefault ./day4-demo-cluster
```

#### 9. Generate the cluster configuration 

We will use the Cluster API ```clusterctl``` command to create a day4 demo cluster ```yaml``` file.

```
clusterctl generate cluster day4-demo-cluster --flavor development \
  --kubernetes-version v1.28.0 \
  --control-plane-machine-count=1 \
  --worker-machine-count=2 \
  > ./day4-demo-cluster/day4-demo-cluster.yaml
```

#### 10. Push and publish the demo cluster
```
kpt alpha rpkg push day4-c33e8e702e5c39ba6099bc7c57d202f9d1d87d6c -ndefault ./day4-demo-cluster
kpt alpha rpkg propose day4-c33e8e702e5c39ba6099bc7c57d202f9d1d87d6c -ndefault
kpt alpha rpkg approve day4-c33e8e702e5c39ba6099bc7c57d202f9d1d87d6c -ndefault
```

#### 11. Check the kind containers coming up
Keep running ```docker ps``` to watch the kind clusters are coming up
```
watch -n 1 docker ps
# Once all kind clusters are up the output of the command should look something like the below
# CONTAINER ID  IMAGE                               PORTS                                           NAMES
# 18293af21270  kindest/node:v1.28.0                                                                day4-demo-cluster-md-0-7kzns-dd769-s9q5j
# 703c5ff55556  kindest/node:v1.28.0                                                                day4-demo-cluster-md-0-7kzns-dd769-bcm77
# 1a120d8e62d3  kindest/node:v1.28.0                0/tcp, 127.0.0.1:32769->6443/tcp                day4-demo-cluster-j4q2c-6tcq7
# b7840dcc4c96  kindest/haproxy:v20230510-486859a6  0/tcp, 0.0.0.0:32768->6443/tcp                  day4-demo-cluster-lb
# 77fc57ebe906  kindest/node:v1.25.3                127.0.0.1:46013->6443/tcp                       demo-control-plane
# 957515554f10  gitea/gitea:1.17.3-rootless         0.0.0.0:2222->2222/tcp, 0.0.0.0:3000->3000/tcp  gitea
```

#### 12. Merge the demo cluster kubeconfig for easy context switching 

```
kind get kubeconfig --name day4-demo-cluster > ~/.kube/demo-config
export KUBECONFIG=~/.kube/config:~/.kube/demo-config
kubectl config view --flatten > all-in-one-kubeconfig.yaml
mv all-in-one-kubeconfig.yaml ~/.kube/config
```

#### 13. Connect to the demo cluster

```
kubectl config get-contexts
# CURRENT   NAME                     CLUSTER                  AUTHINFO                 NAMESPACE
#           kind-day4-demo-cluster   kind-day4-demo-cluster   kind-day4-demo-cluster   
# *         kind-demo                kind-demo                kind-demo

kubectl config use-context kind-day4-demo-cluster
kubectl config get-contexts
# CURRENT   NAME                     CLUSTER                  AUTHINFO                 NAMESPACE
# *         kind-day4-demo-cluster   kind-day4-demo-cluster   kind-day4-demo-cluster   
#           kind-demo                kind-demo                kind-demo   

kubectl get nodes
# NAME                                     STATUS   ROLES           AGE   VERSION
# day4-demo-cluster-j4q2c-6tcq7            NotReady control-plane   2m   v1.28.0
# day4-demo-cluster-md-0-7kzns-dd769-bcm77 NotReady <none>          1m   v1.28.0
# day4-demo-cluster-md-0-7kzns-dd769-s9q5j NotReady <none>          1m   v1.28.0
```

#### 14. Install the Calico CNI 

```
wget https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
kubectl apply -f calico.yaml

# Check the progress of the Calico setup by running the below command
kubectl get pods -n kube-system | grep calico
# Once Calico is up and running the command should show an output like the below
# kube-system   calico-kube-controllers-7ddc4f45bc-294c9                1/1     Running   0          117s
# kube-system   calico-node-8tdhv                                       1/1     Running   0          117s
# kube-system   calico-node-qq82t                                       1/1     Running   0          117s
# kube-system   calico-node-v5nwv                                       1/1     Running   0          117s

# The nodes should now be in Ready status
kubectl get nodes
NAME                                     STATUS ROLES         AGE VERSION
day4-demo-cluster-f9qwb-2zj65            Ready  control-plane 4m  v1.28.0
day4-demo-cluster-md-0-42bdh-x4gt5-29v6x Ready  <none>        m   v1.28.0
day4-demo-cluster-md-0-42bdh-x4gt5-lxntw Ready  <none>        3m  v1.28.0
```

#### 15. Install Config Sync 
Let's install Config Sync into the demo cluster so we can deploy workloads to it later.  
The bellow command is setting up Config Sync with a root sync pointing to the demo cluster gitea repo.

```
export TOKEN=$(cat /demo/giteatoken)

export CS_VERSION=v1.15.1
wget "https://github.com/GoogleContainerTools/kpt-config-sync/releases/download/${CS_VERSION}/config-sync-manifest.yaml"
kubectl apply -f config-sync-manifest.yaml

kubectl create secret generic giteatoken --from-literal=username=demo  \
        --from-literal=token=$TOKEN -n config-management-system

kubectl apply -f /demo/cluster-root-sync.yaml -n config-management-system
```

#### 15. Wait for Config Sync to initialise

```
# Wait for Config Sync to become available
kubectl wait crd --for condition=established rootsyncs.configsync.gke.io

kubectl get pods --all-namespaces | grep config-management
config-management-monitoring   otel-collector-6498d7bfc-ppcgf                          1/1     Running   0             2m43s
config-management-system       reconciler-manager-849b4786f5-bdlwp                     2/2     Running   0             1m
config-management-system       root-reconciler-cluster-root-sync-9ffd7d65d-m8kn4       4/4     Running   0             83s
...
```

#### 16. Register the cluster demo repos with porch

```
kubectl config use-context kind-demo
# The output of the command should look like the following
# Switched to context "kind-demo".

export TOKEN=$(cat /demo/giteatoken)
kpt alpha repo register --namespace default --repo-basic-username=demo --repo-basic-password=$TOKEN \
    --deployment=true http://gitea:3000/demo/demo-cluster.git

kpt alpha repo get
# The output of the command should look like the following
# NAME               TYPE   CONTENT   DEPLOYMENT   READY   ADDRESS
# blueprints         git    Package                True    http://gitea:3000/demo/blueprints.git
# day4               git    Package   true         True    http://gitea:3000/demo/day4.git
# day4-demo          git    Package   true         False   http://gitea:3000/demo/day4-demo.git
# demo-cluster       git    Package   true         True    http://gitea:3000/demo/demo-cluster.git
# kpt-samples        git    Package                True    https://github.com/GoogleContainerTools/kpt-samples.git
# package-examples   git    Package                True    https://github.com/GoogleContainerTools/kpt.git
```

#### 17. Deploy the nginx as the sample app
Clone the ```nginx``` blueprint and approve it for deployment in the demo-cluster repo

```
kpt alpha rpkg clone package-examples-5737e41965b59834fa34cbd1d49cac9afd3a0dad nginx --repository=demo-cluster -n default

kpt alpha rpkg get --name=nginx | grep demo-cluster
# The output of the command should look like the following
# demo-cluster-332e460230cb2124afbb18eb0bbe9045639bb347       nginx  v1      false  Draft     demo-cluster

# Propose package to be published
kpt alpha rpkg propose demo-cluster-332e460230cb2124afbb18eb0bbe9045639bb347 -n default

kpt alpha rpkg get --name=nginx | grep demo-cluster
# The output of the command should look like the following
# demo-cluster-332e460230cb2124afbb18eb0bbe9045639bb347       nginx  v1      false  Proposed  demo-cluster

# Approve a proposal to publish
kpt alpha rpkg approve demo-cluster-332e460230cb2124afbb18eb0bbe9045639bb347 -n default

kpt alpha rpkg get --name=nginx | grep demo-cluster
# The output of the command should look like the following
# demo-cluster-332e460230cb2124afbb18eb0bbe9045639bb347       nginx  v1  v1  true  Published  demo-cluster
```

#### 18. Check the nginx sample app deployment status in the demo cluster
```
kubectl config use-context kind-day4-demo-cluster

kubectl get pods
# The output of the command should look like the following
# NAME                        READY   STATUS    RESTARTS   AGE
# my-nginx-584b4f6d78-99kr7   1/1     Running   0          13s
# my-nginx-584b4f6d78-mkmws   1/1     Running   0          13s
# my-nginx-584b4f6d78-mzgcc   1/1     Running   0          13s
# my-nginx-584b4f6d78-xchgh   1/1     Running   0          13s
```
