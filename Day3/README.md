# Day 3 - Provision a simple app using Config Sync, kpt and porch

## Introduction

This is demo builds on the groundwork we laid out in the [Day 1](../Day1/README.md) and [Day 2](../Day2/README.md) demos.  

Additionally, in this demo we will use [porch](https://github.com/GoogleContainerTools/kpt/blob/main/site/guides/porch-user-guide.md) to deploy an app that is packaged as a [kpt package](https://kpt.dev/book/03-packages/).  

For our convenience both the ```gitea``` and the ```kind``` containers are already up and running.  
  
We will conclude the demo by setting up and accessing the [porch UI](https://kpt.dev/guides/porch-ui-installation) which will give us an alternative way to interact with porch through a graphical interface rather than through the command line.  
 
![Configuration as Data Day3](/images/nephio_cad_day3.png)  

## Instructions

#### 1. Build the demo environment Docker image and then run it
We build the Docker image from to the [Dockerfile](./Dockerfile) in the current directory.

```
docker build -t workstation:day3 .

docker run --rm -d --env='DOCKER_OPTS=' --volume=/var/lib/docker --privileged \
           --name demo -p 8080:80 -p 3000:3000 -p 7007:7007 workstation:day3
```

#### 2. Follow the boot/demo logs
When starting the demo container image it will set up the demo environment for you.  

Depending on the spec of your environment this might take quite some time.

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
* Both the gitea and kind containers are running

Note that you can also access the gitea repo by pointing your browser to [http://localhost:3000](http://localhost:3000). Use ```demo/demo``` to login to the gitea repository server.


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
# NAMESPACE            NAME                                         READY   STATUS    RESTARTS   AGE
# kube-system          coredns-565d847f94-75jlx                     1/1     Running   0          18s
# kube-system          coredns-565d847f94-97ffj                     1/1     Running   0          18s
# kube-system          etcd-demo-control-plane                      1/1     Running   0          33s
# kube-system          kindnet-5zmdd                                1/1     Running   0          18s
# kube-system          kube-apiserver-demo-control-plane            1/1     Running   0          33s
# kube-system          kube-controller-manager-demo-control-plane   1/1     Running   0          32s
# kube-system          kube-proxy-pgvtl                             1/1     Running   0          18s
# kube-system          kube-scheduler-demo-control-plane            1/1     Running   0          32s
# local-path-storage   local-path-provisioner-684f458cdd-wzk6v      1/1     Running   0          18s
```

#### 5. Configure git with the base config

Let's configure git with the base config items it expects to run properly (note we totally make up these config values). 


```
git config --global user.email "demo@d.com"
git config --global user.name "demo"
```

#### 6. Install porch


```
wget https://github.com/GoogleContainerTools/kpt/releases/download/porch%2Fv0.0.18/deployment-blueprint.tar.gz
mkdir porch-install
tar xzf deployment-blueprint.tar.gz -C porch-install
kubectl apply -f porch-install
# The output should look something like the below
# customresourcedefinition.apiextensions.k8s.io/functions.config.porch.kpt.dev created
# customresourcedefinition.apiextensions.k8s.io/packagerevs.config.porch.kpt.dev created
# customresourcedefinition.apiextensions.k8s.io/packagevariants.config.porch.kpt.dev created
# customresourcedefinition.apiextensions.k8s.io/packagevariantsets.config.porch.kpt.dev created
# customresourcedefinition.apiextensions.k8s.io/remoterootsyncsets.config.porch.kpt.dev created
# customresourcedefinition.apiextensions.k8s.io/repositories.config.porch.kpt.dev created
# customresourcedefinition.apiextensions.k8s.io/rootsyncsets.config.porch.kpt.dev created
# customresourcedefinition.apiextensions.k8s.io/workloadidentitybindings.config.porch.kpt.dev created
# namespace/porch-system created
# namespace/porch-fn-system created
# serviceaccount/porch-fn-runner created
# deployment.apps/function-runner created
# service/function-runner created
# configmap/pod-cache-config created
# serviceaccount/porch-server created
# deployment.apps/porch-server created
# service/api created
# apiservice.apiregistration.k8s.io/v1alpha1.porch.kpt.dev created
# clusterrole.rbac.authorization.k8s.io/aggregated-apiserver-clusterrole created
# role.rbac.authorization.k8s.io/aggregated-apiserver-role created
# role.rbac.authorization.k8s.io/porch-function-executor created
# clusterrolebinding.rbac.authorization.k8s.io/sample-apiserver-clusterrolebinding created
# rolebinding.rbac.authorization.k8s.io/sample-apiserver-rolebinding created
# rolebinding.rbac.authorization.k8s.io/porch-function-executor created
# rolebinding.rbac.authorization.k8s.io/porch-auth-reader created
# clusterrolebinding.rbac.authorization.k8s.io/porch:system:auth-delegator created
# serviceaccount/porch-controllers created
# deployment.apps/porch-controllers created
# clusterrole.rbac.authorization.k8s.io/porch-controllers created
# clusterrole.rbac.authorization.k8s.io/porch-controllers-functiondiscovery created
# clusterrolebinding.rbac.authorization.k8s.io/porch-system:porch-controllers-functiondiscovery created
# clusterrole.rbac.authorization.k8s.io/porch-controllers-packagevariants created
# clusterrolebinding.rbac.authorization.k8s.io/porch-system:porch-controllers-packagevariants created
# clusterrole.rbac.authorization.k8s.io/porch-controllers-packagevariantsets created
# clusterrolebinding.rbac.authorization.k8s.io/porch-system:porch-controllers-packagevariantsets created
# clusterrole.rbac.authorization.k8s.io/porch-controllers-remoterootsyncsets created
# clusterrolebinding.rbac.authorization.k8s.io/porch-system:porch-controllers-remoterootsyncsets created
# clusterrole.rbac.authorization.k8s.io/porch-controllers-rootsyncsets created
# clusterrolebinding.rbac.authorization.k8s.io/porch-system:porch-controllers-rootsyncsets created
# clusterrole.rbac.authorization.k8s.io/porch-controllers-workloadidentitybinding created
# clusterrolebinding.rbac.authorization.k8s.io/porch-system:porch-controllers-workloadidentitybinding created
# customresourcedefinition.apiextensions.k8s.io/configmanagements.configmanagement.gke.io created
# namespace/config-management-system created
# namespace/config-management-monitoring created
# clusterrole.rbac.authorization.k8s.io/config-management-operator created
# clusterrolebinding.rbac.authorization.k8s.io/config-management-operator created
# serviceaccount/config-management-operator created
# deployment.apps/config-management-operator created
```

#### 7. Wait for the porch server components to come up


```
kubectl wait deployment --for=condition=Available porch-server -n porch-system
# The output should look something like the below
# deployment.apps/porch-server condition met

kubectl api-resources | grep porch
# The output should look something like the below
# functions                                      config.porch.kpt.dev/v1alpha1          true         Function
# packagerevs                                    config.porch.kpt.dev/v1alpha1          true         PackageRev
# packagevariants                                config.porch.kpt.dev/v1alpha1          true         PackageVariant
# packagevariantsets                             config.porch.kpt.dev/v1alpha2          true         PackageVariantSet
# remoterootsyncsets                             config.porch.kpt.dev/v1alpha1          true         RemoteRootSyncSet
# repositories                                   config.porch.kpt.dev/v1alpha1          true         Repository
# rootsyncsets                                   config.porch.kpt.dev/v1alpha1          true         RootSyncSet
# workloadidentitybindings                       config.porch.kpt.dev/v1alpha1          true         WorkloadIdentityBinding
# functions                                      porch.kpt.dev/v1alpha1                 true         Function
# packagerevisionresources                       porch.kpt.dev/v1alpha1                 true         PackageRevisionResources
# packagerevisions                               porch.kpt.dev/v1alpha1                 true         PackageRevision
# packages                                       porch.kpt.dev/v1alpha1                 true         Package

watch -n 1 kubectl get pods --all-namespaces
# The output should look something like the below
# Wait until all pods reach the 'Running' status
# NAMESPACE                  NAME                                          READY   STATUS    RESTARTS   AGE
# config-management-system   config-management-operator-58ff7dbd66-mntjn   1/1     Running   0          2m13s
# porch-fn-system            apply-replacements-85913d4e                   1/1     Running   0          2m1s
# porch-fn-system            apply-setters-4d429572                        1/1     Running   0          2m1s
# porch-fn-system            create-setters-0220cc87                       1/1     Running   0          2m1s
# porch-fn-system            enable-gcp-services-a56558d5                  1/1     Running   0          2m1s
# porch-fn-system            ensure-name-substring-33ff7d9a                1/1     Running   0          2m1s
# porch-fn-system            export-terraform-571fedd3                     1/1     Running   0          2m1s
# porch-fn-system            gatekeeper-a1c19318                           1/1     Running   0          2m1s
# porch-fn-system            generate-folders-4511c517                     1/1     Running   0          2m1s
# porch-fn-system            kubeval-bb88cbcc                              1/1     Running   0          2m1s
# porch-fn-system            remove-local-config-resources-2825914e        1/1     Running   0          2m1s
# porch-fn-system            search-replace-6864b06b                       1/1     Running   0          2m1s
# porch-fn-system            set-annotations-76d65ebd                      1/1     Running   0          2m1s
# porch-fn-system            set-enforcement-action-aea09be3               1/1     Running   0          2m1s
# porch-fn-system            set-image-49c7a466                            1/1     Running   0          2m1s
# porch-fn-system            set-labels-0dfc3c8a                           1/1     Running   0          2m1s
# porch-fn-system            set-namespace-f930d924                        1/1     Running   0          2m1s
# porch-fn-system            set-project-id-966c9e51                       1/1     Running   0          2m1s
# porch-fn-system            starlark-6ba3971c                             1/1     Running   0          2m1s
# porch-fn-system            upsert-resource-77196bdb                      1/1     Running   0          2m1s
# porch-system               function-runner-6ff7ff6744-gn27b              1/1     Running   0          2m16s
# porch-system               function-runner-6ff7ff6744-zn69q              1/1     Running   0          2m16s
# porch-system               porch-controllers-5467dfd9c7-jczhx            1/1     Running   0          2m15s
# porch-system               porch-server-656c6fb555-bpg8m                 1/1     Running   0          2m16s
...
```

#### 8. Enable Config Sync


```
kubectl apply -f /demo/config-management.yaml
# The output should look something like the below
# configmanagement.configmanagement.gke.io/config-management created
```

#### 9. Wait for Config Sync to be up and running
Let's run the below command until we see all the ```pods``` to be up and running.

```
kubectl get pods --all-namespaces
# The output should look something like the below
# NAMESPACE                      NAME                                                READY   STATUS    RESTARTS   AGE
# config-management-monitoring   otel-collector-659876667-kd7vc                      1/1     Running   0          22s
# config-management-system       config-management-operator-58ff7dbd66-mntjn         1/1     Running   0          6m45s
# config-management-system       reconciler-manager-679c4ccc96-j8xhf                 2/2     Running   0          22s
...
```

#### 10. Create the gitea secret for porch
```
kubectl create secret generic giteatoken --from-literal=username=demo \
        --from-literal=token=$(cat /demo/giteatoken) -n config-management-system
```

#### 11. Create the RootSync
```
kubectl apply -f /demo/demo-root-sync.yaml -n config-management-system
```

#### 12. Register the repos with porch


```
kpt alpha repo register --namespace default --repo-basic-username=demo --repo-basic-password=$(cat /demo/giteatoken) \
    http://gitea:3000/demo/blueprints.git
kpt alpha repo register --namespace default --repo-basic-username=demo --repo-basic-password=$(cat /demo/giteatoken) \
    --deployment=true http://gitea:3000/demo/day3.git
kpt alpha repo register --namespace default --directory=package-examples --name=package-examples \
    https://github.com/GoogleContainerTools/kpt.git

kpt alpha repo get
# The output should look something like the below
# blueprints         git    Package                True    http://gitea:3000/demo/blueprints.git
# day3               git    Package   true         True    http://gitea:3000/demo/day3.git
# package-examples   git    Package                True    https://github.com/GoogleContainerTools/kpt.git
```

#### 13. Deploy the nginx as the sample app
Clone the ```nginx``` blueprint and approve it for deployment in the day3 repo

```
kpt alpha rpkg clone package-examples-5737e41965b59834fa34cbd1d49cac9afd3a0dad nginx --repository=day3 -n default

kpt alpha rpkg get --name=nginx
# The output should look something like the below
# NAME                                                        PACKAGE   WORKSPACENAME   REVISION   LATEST   LIFECYCLE   REPOSITORY
# day3-b07844564671756e141cec89dd096bdae8c25997               nginx     v1                         false    Draft       day3
# package-examples-0611e7cc531b88067fcdafb775dd2c2c446cafae   nginx     main            main       false    Published   package-examples
...

# Propose package to be published
kpt alpha rpkg propose day3-b07844564671756e141cec89dd096bdae8c25997 -n default
# The output should look something like the below
# day3-b07844564671756e141cec89dd096bdae8c25997 proposed

kpt alpha rpkg get --name=nginx
# The output should look something like the below
# NAME                                                        PACKAGE   WORKSPACENAME   REVISION   LATEST   LIFECYCLE   REPOSITORY
# day3-b07844564671756e141cec89dd096bdae8c25997               nginx     v1                         false    Proposed    day3
# package-examples-0611e7cc531b88067fcdafb775dd2c2c446cafae   nginx     main            main       false    Published   package-examples
...

# Approve a proposal to publish
kpt alpha rpkg approve day3-b07844564671756e141cec89dd096bdae8c25997 -n default
# The output should look something like the below
# day3-b07844564671756e141cec89dd096bdae8c25997 approved
```

#### 14. Witness nginx running in the cluster


```
kubectl get pods                 
# The output should look something like the below
# NAME                        READY   STATUS    RESTARTS   AGE
# my-nginx-578b7694b4-bjtsm   1/1     Running   0          47s
# my-nginx-578b7694b4-jjrcg   1/1     Running   0          47s
# my-nginx-578b7694b4-nnqnc   1/1     Running   0          47s
# my-nginx-578b7694b4-pfvt7   1/1     Running   0          47s
```

#### 15. Register kpt-samples repo


```
kpt alpha repo register --namespace=default https://github.com/GoogleContainerTools/kpt-samples.git

kpt alpha repo get
# The output should look something like the below
# blueprints         git    Package                True    http://gitea:3000/demo/blueprints.git
# day3               git    Package   true         True    http://gitea:3000/demo/day3.git
# kpt-samples        git    Package                True    https://github.com/GoogleContainerTools/kpt-samples.git
# package-examples   git    Package                True    https://github.com/GoogleContainerTools/kpt.git
```

#### 16. Clone and pull the backstage-ui-plugin


```
kpt alpha rpkg clone kpt-samples-4eec8cab06d8695eb329c3e068705c2525a55c7c backstage-ui-plugin --repository=blueprints -n default

kpt alpha rpkg pull blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c backstage-ui-plugin -n default
```

#### 17. Configure the backstage-ui-plugin


```
rm backstage-ui-plugin/externalsecret-openid.yaml
cp /demo/apply-replacements.yaml backstage-ui-plugin/
cp /demo/apply-replacements-config.yaml backstage-ui-plugin/
cp /demo/set-image-config.yaml backstage-ui-plugin/

# Set the mutators
cat /demo/apply-replacements-mutator.yaml >> backstage-ui-plugin/Kptfile
cat /demo/set-image-mutator.yaml >> backstage-ui-plugin/Kptfile

# Render the pipeline
kpt fn render backstage-ui-plugin

cp /demo/cluster-role-binding.yaml backstage-ui-plugin/
cp /demo/sa.yaml backstage-ui-plugin/ 
```

#### 18. Push, propose and approve the porch backstage-ui-plugin blueprint


```
kpt alpha rpkg push blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c backstage-ui-plugin -n default
kpt alpha rpkg propose blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c -n default
kpt alpha rpkg approve blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c -n default
```

#### 19. Clone, propose and approve the porch backstage-ui-plugin


```
kpt alpha rpkg clone blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c backstage-ui-plugin --repository=day3 -n default
kpt alpha rpkg propose day3-47808733283185155850a67885600ba1eca6d75b -n default
kpt alpha rpkg approve day3-47808733283185155850a67885600ba1eca6d75b -n default
```

#### 20. Witness the porch backstage-ui-plugin running
Once the porch backstage UI ```pod``` is up and running you can port forward the service to make it available on your browser through ```localhost```.

```
watch -n 1 kubectl get pods --all-namespaces
# The output should look something like the below
# Wait until the backstage-ui-plugin pod is reaching 'Running' status
# NAMESPACE                      NAME                                                READY   STATUS    RESTARTS      AGE
# backstage-ui-plugin            backstage-5dcbd6c95c-nj7mf                          1/1     Running   0             14m
...

kubectl port-forward --address 0.0.0.0 -n backstage-ui-plugin svc/backstage 7007
```

#### 21. Connect to the porch backstage UI 
Connect to the porch backstage UI by pointing your browser to [http://localhost:7007](http://localhost:7007).
You can now explore the porch resources through the backstage UI.
```
