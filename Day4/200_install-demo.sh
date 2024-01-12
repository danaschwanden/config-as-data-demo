#!/bin/bash
# shellcheck disable=SC1091
export USER=user
BASE=$(pwd)
export BASE
export LC_ALL=C.UTF-8
echo "-----------------"
echo "Change to install directory"
cd /demo
echo "-----------------"
echo "Waiting for Docker to start"
while (! docker stats --no-stream ); do
  # Docker takes a few seconds to initialize
  echo "Waiting for Docker to launch..."
  sleep 1
done
echo "-----------------"
echo "Create kind docker network"
docker network create kind
echo "-----------------"
echo "Run gitea repo container"
docker run --network=kind -d --rm --name gitea -p 3000:3000 -p 2222:2222 -e INSTALL_LOCK=true gitea/gitea:1.17.3-rootless
echo "-----------------"
echo "Create kind cluster"
kind create cluster --config /demo/kind-cluster-with-extramounts.yaml
echo "-----------------"
echo "Install clusterctl"
curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.5.0/clusterctl-linux-amd64 -o clusterctl
sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl
clusterctl version
export CLUSTER_TOPOLOGY=true
clusterctl init --infrastructure docker
echo "-----------------"
echo "Create demo user"
TOKEN=$(docker exec gitea gitea admin user create --username demo --password demo --must-change-password=false --access-token --email=demo@d.com  | grep 'Access token' | cut -d" " -f6)
echo $TOKEN > giteatoken
echo "-----------------"
echo "Create config repos"
curl -k -H "Authorization: token $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json" -d '{"auto_init": true, "name": "day4"}' http://localhost:3000/api/v1/user/repos
curl -k -H "Authorization: token $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json" -d '{"auto_init": true, "name": "blueprints"}' http://localhost:3000/api/v1/user/repos
echo "-----------------"
echo "Setting kubeconfig..."
mkdir /home/user/.kube
cp /root/.kube/config /home/user/.kube/
chown -R user:user /home/user/.kube
echo "-----------------"
echo "Install porch..."
wget -q https://github.com/GoogleContainerTools/kpt/releases/download/porch%2Fv0.0.18/deployment-blueprint.tar.gz
mkdir porch-install
tar xzf deployment-blueprint.tar.gz -C porch-install
kubectl apply -f porch-install
echo "-----------------"
echo "Wait for porch-server, porch-controllers and function-runner to become available..."
kubectl wait deployment --for=condition=Available --timeout=-1s porch-server -n porch-system
kubectl wait deployment --for=condition=Available --timeout=-1s function-runner -n porch-system
kubectl wait deployment --for=condition=Available --timeout=-1s porch-controllers -n porch-system
echo "-----------------"
echo "Enable Config Sync"
kubectl apply -f /demo/config-management.yaml
echo "-----------------"
echo "Create gitea secret for porch"
kubectl create secret generic giteatoken --from-literal=username=demo --from-literal=token=$(cat /demo/giteatoken) -n config-management-system
echo "-----------------"
echo "Wait for Config Sync to become available..."
kubectl wait deployment --for=condition=Available --timeout=-1s config-management-operator -n config-management-system
until kubectl get crd rootsyncs.configsync.gke.io >/dev/null 2>&1; do
  echo "Waiting for rootsyncs.configsync.gke.io"
  sleep 1
done
kubectl wait crd --for condition=established rootsyncs.configsync.gke.io
echo "-----------------"
echo "Create demo-root-sync"
kubectl apply -f /demo/demo-root-sync.yaml -n config-management-system
kubectl wait deployment --for=condition=Available --timeout=-1s reconciler-manager -n config-management-system
kubectl wait deployment --for=condition=Available --timeout=-1s root-reconciler-demo-root-sync -n config-management-system
echo "-----------------"
echo "Register the repos with porch"
kpt alpha repo register --namespace=default --repo-basic-username=demo --repo-basic-password=$(cat /demo/giteatoken) http://gitea:3000/demo/blueprints.git
kpt alpha repo register --namespace=default --repo-basic-username=demo --repo-basic-password=$(cat /demo/giteatoken) --deployment=true http://gitea:3000/demo/day4.git
kpt alpha repo register --namespace=default https://github.com/GoogleContainerTools/kpt-samples.git
kpt alpha repo register --namespace=default --directory=package-examples --name=package-examples https://github.com/GoogleContainerTools/kpt.git
echo "-----------------"
echo "Clone, Pull and Configure the backstage-ui-plugin blueprint"
kpt alpha rpkg clone kpt-samples-4eec8cab06d8695eb329c3e068705c2525a55c7c backstage-ui-plugin --repository=blueprints -n default
kpt alpha rpkg pull blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c backstage-ui-plugin -n default
rm backstage-ui-plugin/externalsecret-openid.yaml
cp /demo/apply-replacements.yaml backstage-ui-plugin/
cp /demo/apply-replacements-config.yaml backstage-ui-plugin/
cp /demo/set-image-config.yaml backstage-ui-plugin/

# Set the mutators
cat /demo/apply-replacements-mutator.yaml >> backstage-ui-plugin/Kptfile
cat /demo/set-image-mutator.yaml >> backstage-ui-plugin/Kptfile

# Render the pipeline
kpt fn render backstage-ui-plugin

cp cluster-role-binding.yaml backstage-ui-plugin/
cp sa.yaml backstage-ui-plugin/ 
echo "-----------------"
echo "Push, Propose and Approve the backstage-ui-plugin blueprint"
kpt alpha rpkg push blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c backstage-ui-plugin -n default
kpt alpha rpkg propose blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c -n default
kpt alpha rpkg approve blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c -n default
echo "-----------------"
echo "Deploy the backstage-ui-plugin"
kpt alpha rpkg clone blueprints-e057fa5d111e5249f93f350424d7e8c0159bbc3c backstage-ui-plugin --repository=day4 -n default
kpt alpha rpkg propose day4-259a27ee5fb839ce4e7dc246bb8b59354fcbae8f -n default
kpt alpha rpkg approve day4-259a27ee5fb839ce4e7dc246bb8b59354fcbae8f -n default
echo "-----------------"
echo "Wait for backstage to become available..."
until kubectl get deployments backstage -n backstage-ui-plugin >/dev/null 2>&1; do
  echo "Waiting for backstage deployment to sync"
  sleep 1
done
kubectl wait deployment --for=condition=Available --timeout=-1s backstage -n backstage-ui-plugin
echo "-----------------"
cd "$BASE" || exit
echo "demo installation done"
echo "-----------------"
