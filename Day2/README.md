# Day 2 - Provision a simple app using Config Sync and kpt

## Introduction
This is a very similar demo to the one in the [Day 1](../Day1/README.md) folder.  
However, in this demo we will not create the app's Kubernetes deployment manifest ourselves but rather we will deploy an app that is packaged as a [kpt package](https://kpt.dev/book/03-packages/).   
For our convenience the the ```kind``` container is already running and pre-configured.
We will use kpt to setup both ```gitea``` and Config Sync first and the pull the config into the cluster.  

![Configuration as Data Day2](/images/nephio_cad_day2.png)  

## Instructions

#### 1. Build the demo environment Docker image and then run it
We build the Docker image from to the [Dockerfile](./Dockerfile) in the current directory.  

```
docker build -t workstation:day2 .

docker run --rm -d --env='DOCKER_OPTS=' --volume=/var/lib/docker --privileged --name demo -v .:/demo \
           -p 8080:80 -p 3000:31000 workstation:day2
```

#### 2. Follow the boot/demo logs
When starting the demo container image it will set up the demo environment for you.  

Depending on the spec of your environment this might take a bit of time.

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
* The kind container is running
```
docker ps
# The output should look something like the below:
# CONTAINER ID IMAGE                COMMAND                STATUS     PORTS                     NAMES
# 6991fc0789bc kindest/node:v1.25.3 "/usr/local/bin/entr…" 59 seconds 127.0.0.1:46443->6443/tcp demo-control-plane

kubectl get nodes
# The output should look something like the below:
# NAME               STATUS ROLES         AGE   VERSION
# demo-control-plane Ready  control-plane 1m23s v1.25.3
```

#### 5. Initialize the environment
The following commands will
* Initialize the environment varliables,
* Create the gitea namespace,
* Create the secrets with the gitea passwords 

```
source /demo/envs
kubectl create namespace $GITEA_K8S_NAMESPACE
kubectl create secret generic gitea-postgresql -n $GITEA_K8S_NAMESPACE \
    --from-literal=postgres-password=$GITEA_K8S_POSTGRES_PASSWORD \
    --from-literal=password=$GITEA_K8S_DB_PASSWORD
kubectl label secret gitea-postgresql -n gitea "app.kubernetes.io/name=postgresql"
kubectl label secret gitea-postgresql -n gitea "app.kubernetes.io/instance=gitea"

kubectl create secret generic git-user-secret -n $GITEA_K8S_NAMESPACE \
    --type='kubernetes.io/basic-auth' \
    --from-literal=username=$GITEA_K8S_USERNAME \
    --from-literal=password=$GITEA_K8S_PASSWORD
```

#### 6. Setup gitea

```
kpt pkg get --for-deployment https://github.com/nephio-project/nephio-example-packages/gitea@v1.0.1
sed -i "s/cpu: 250m/cpu: 50m/g" gitea/deployment-memcached.yaml
kpt fn render gitea
kpt live init gitea
kpt live apply gitea --reconcile-timeout 15m --output=table
```

#### 7. Setup Config Sync

```
kpt pkg get --for-deployment https://github.com/nephio-project/nephio-example-packages.git/configsync@v1.0.1
kpt fn render configsync
kpt live init configsync
kpt live apply configsync --reconcile-timeout=15m --output=table
```

#### 8. Create the day2 repo and an access token

```
TOKEN=$(kubectl exec -it gitea-0 -n gitea -- \
        su -c 'gitea admin user generate-access-token --username nephio \
               --token-name ConfigSyncToken --scopes all --raw' git | \
               tail -1 | sed -e "s/\r//g")

curl -k -H "Authorization: token $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json" \
    -d '{"auto_init": true, "name": "day2"}' http://localhost:31000/api/v1/user/repos
```

#### 9. Configure config sync
```
kubectl create secret generic giteatoken --from-literal=username=nephio \
        --from-literal=token=$TOKEN -n config-management-system

kubectl apply -f /demo/demo-root-sync.yaml -n config-management-system
```

#### 10. Push the demo app to the gitea repo

With all this in place we are good to go and put some content to the "day2" repo from where Config Sync fetches it into the Kubernetes cluster.
Let's configure git with the base config items it expects to run properly (note we totally make up these config values). 

```
git config --global user.email "demo@d.com"
git config --global user.name "demo"
```

Ready, steady, go!
* Let's clone the "day2" repo
* Fetch the nginx kpt package
* Remove the Kubernetes Service object from the package
* Add the lot, commmit and push to the updates back to the remote repo. 

```
git clone http://demo:demo@localhost:3000/nephio/day2.git
cd day2
kpt pkg get https://github.com/GoogleContainerTools/kpt/package-examples/nginx@v0.9
mv nginx config-sync-day2
rm config-sync-day2/svc.yaml
kpt pkg tree
# The output should look something like the below
# day2
# └── Package "config-sync-day2"
#     ├── [Kptfile]  Kptfile nginx
#     └── [deployment.yaml]  Deployment my-nginx
git add .
git commit -m 'Adds nginx deployment to root sync'
git push origin main
```

#### 11. Check out the kpt package resources running on the Cluster

Config Sync will start taking note of the new config for nginx.
Within a few seconds you should see the nginx pods starting up in the kind cluster.

```
kubectl get pods
# The output should look something like the below
# NAME                        READY   STATUS    RESTARTS   AGE
# my-nginx-68fc675d59-fkdxf   1/1     Running   0          7m6s
# my-nginx-68fc675d59-qjjmf   1/1     Running   0          7m6s
# my-nginx-68fc675d59-vrlpm   1/1     Running   0          7m6s
# my-nginx-68fc675d59-xdmrg   1/1     Running   0          7m5s
...
```
