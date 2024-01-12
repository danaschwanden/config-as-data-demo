# Day 1 - Provision a simple app using Config Sync and Kubernetes Manifests

## Introduction
In this demo we start simple and only spin up a [nginx](https://nginx.org/) deployment using [Config Sync](https://cloud.google.com/anthos-config-management/docs/config-sync-overview).  
For this we need a [kind](https://kind.sigs.k8s.io/) Kubernetes cluster to run Config Sync and a [gitea](https://gitea.io) repository to host our nginx Kubernetes Deployment manifest.  
This is as simple as it gets but lends itself as a great getting started demo.  

![Configuration as Data Day1](/images/nephio_cad_day1.png)   

## Instructions

#### 1. Bring up the demo environment
Run the following command on your laptop to spin up a Docker container that will provide the environment for this demo.  

```
docker run --rm -d --env='DOCKER_OPTS=' --volume=/var/lib/docker --privileged --name demo -v .:/demo \
           -p 8080:80 -p 3000:3000 us-central1-docker.pkg.dev/cloud-workstations-images/predefined/code-oss
```

#### 2. Connect to the demo environment
Connect to the Workstation by pointing your browser to [http://localhost:8080](http://localhost:8080).
Then open a [Terminal window](../README.md#Instructions) to execute the commands below.

#### 3. Create the Docker Network
kind would create a [Docker Network](https://docs.docker.com/network/) for us.  
However, we do this ourselves here to make sure we can run gitea on the same network so we can communicate between the gitea and kind containers more easily later.

```
docker network create kind
```

#### 4. Start the gitea repository container
We are good to start gitea now. gitea will host our repository containing the nginx Kubernetes Deployment manifest.

```
docker run --network=kind -d --rm --name gitea -p 3000:3000 -p 2222:2222 \
           -e INSTALL_LOCK=true gitea/gitea:1.20.5-rootless
```

#### 5. Create the kind Cluster
Next we bring up a kind (Kubernetes in Docker) cluster.

```
kind create cluster --name demo
```

#### 6. Create the gitea repo for the demo app manifests
gitea offers a neat [REST API](https://docs.gitea.com/development/api-usage). We use it to create the empty repositories to deploy the Kubernetes mainfests to.
Note that we will need an access token to interact with the gitea REST API.  
The below commands illustrate how a token is generated and then used to create the empty "day1" repository.

```
docker exec gitea gitea admin user create --username demo --password demo \
       --must-change-password=false --email=demo@d.com
TOKEN=$(docker exec gitea gitea admin user generate-access-token --username demo \
       --token-name ConfigSyncToken --scopes all | cut -d" " -f6)
echo $TOKEN > giteatoken

curl -k -H "Authorization: token $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json" \
     -d '{"auto_init": true, "name": "day1"}' http://localhost:3000/api/v1/user/repos
```
Note that you can also access the gitea repo by pointing your browser to [http://localhost:3000](http://localhost:3000). Use ```demo/demo``` to login to the gitea repository server.


#### 7. Start Config Sync
We are getting close. The final infrastructure component we still need is Config Sync.
The bellow command is setting up Config Sync with a root sync pointing to the gitea repo we just created.

```
export CS_VERSION=v1.15.3
kubectl apply -f \
  "https://github.com/GoogleContainerTools/kpt-config-sync/releases/download/${CS_VERSION}/config-sync-manifest.yaml"
kubectl create secret generic giteatoken --from-literal=username=demo  \
        --from-literal=token=$TOKEN -n config-management-system

kubectl apply -f /demo/demo-root-sync.yaml -n config-management-system
```

Wait for Config Sync to start fully. You can run the following command to check on the progress.
```
kubectl get pods -A
# The output should look similiar to the below:
# NAMESPACE                     NAME                                              READY STATUS    RESTARTS AGE
# config-management-monitoring  otel-collector-57fc48c4ff-mzcxl                   1/1   Running   0        30s
# config-management-system      reconciler-manager-78dc889567-cpgwg               2/2   Running   0        2m
# config-management-system      root-reconciler-demo-root-sync-84bb59c8b-qtzp2    4/4   Running   0        29s
# resource-group-system         resource-group-controller-manager-795b9cb9c-dkfzz 2/2   Running   0        2m
# ...
```


#### 8. Push the demo app to the gitea repo

With all this in place we are good to go and push some content to the "day1" repo from where Config Sync fetches it into the Kubernetes cluster.  
Let's configure git with the base config items it expects to run properly (note we totally make up these config values).

```
git config --global user.email "demo@d.com"
git config --global user.name "demo"
```

Ready, steady, go!
* Let's clone the "day1" repo
* Create a new subdirectory
* Copy the nginx-deployment.yaml file to the subdirectory
* Add the lot, commmit and push to the updates back to the remote repo. 

```
git clone http://demo:demo@localhost:3000/demo/day1.git
mkdir day1/config-sync-day1
cp /demo/nginx-deployment.yaml day1/config-sync-day1/
cd day1/
git add .
git commit -m 'Adds nginx deployment to root sync'
git push origin main
```

#### 9. Check out the app deployment running on the Cluster

Config Sync will start taking note of the new config for nginx.  
Within a few seconds you should see the nginx pods starting up in the kind cluster.

```
kubectl get pods
# The output should looks something like the below:
# NAME                              READY STATUS  RESTARTS AGE
# nginx-deployment-7fb96c846b-s4xnz 1/1   Running 0        16s
# nginx-deployment-7fb96c846b-w76dz 1/1   Running 0        16s
```
