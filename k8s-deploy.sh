#!/bin/sh
# use k3s if present
K3S=$(which k3s)
$K3S kubectl create secret generic tt2-playarea \
    --from-literal=secret="$(openssl rand -hex 32)"
$K3S kubectl apply -f k8s-deployment.yml
$K3S kubectl expose deployment tt2 --port=5000
$K3S kubectl apply -f tt2-traefik.yml
