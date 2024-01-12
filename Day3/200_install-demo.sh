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
kind create cluster --name demo
echo "-----------------"
echo "Create demo user"
TOKEN=$(docker exec gitea gitea admin user create --username demo --password demo --must-change-password=false --access-token --email=demo@d.com  | grep 'Access token' | cut -d" " -f6)
echo $TOKEN > giteatoken
echo "-----------------"
echo "Create config repos"
curl -k -H "Authorization: token $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json" -d '{"auto_init": true, "name": "day3"}' http://localhost:3000/api/v1/user/repos
curl -k -H "Authorization: token $TOKEN" -H "Content-Type: application/json" -H "Accept: application/json" -d '{"auto_init": true, "name": "blueprints"}' http://localhost:3000/api/v1/user/repos
echo "-----------------"
echo "Setting kubeconfig..."
mkdir /home/user/.kube
cp /root/.kube/config /home/user/.kube/
chown -R user:user /home/user/.kube
echo "-----------------"
cd "$BASE" || exit
echo "demo installation done"
echo "-----------------"
