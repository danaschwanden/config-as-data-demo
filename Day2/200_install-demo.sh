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
echo "Create kind cluster"
kind create cluster --config kind-config.yaml
echo "-----------------"
echo "Setting kubeconfig..."
mkdir /home/user/.kube
cp /root/.kube/config /home/user/.kube/
chown -R user:user /home/user/.kube
echo "-----------------"
cd "$BASE" || exit
echo "demo installation done"
echo "-----------------"
