#!/usr/bin/env bash

# App Mesh charts smoke test

set -o errexit

REPO_ROOT=$(git rev-parse --show-toplevel)
export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

namespace=appmesh-system

function finish {
  kubectl -n $namespace get pods || true
  kubectl -n $namespace logs -l app.kubernetes.io/name=appmesh-controller || true
  kubectl -n $namespace logs -l app.kubernetes.io/name=appmesh-inject || true
}
trap finish EXIT

function prepare {
  kubectl create ns $1
  kubectl apply -k ./stable/appmesh-controller/crds
}

function install {
  helm upgrade -i $1 ./stable/$1 --namespace $2
}

function waitForDeploy {
  echo ">>> Waiting for deployment $1 "
  retries=10
  count=0
  ok=false
  until ${ok}; do
    kubectl -n $2 describe deployment/$1 && ok=true || ok=false
    echo -n '.'
    sleep 5
    count=$(($count + 1))
    if [[ ${count} -eq ${retries} ]]; then
      echo ' No more retries left'
      break
    fi
  done
  echo ""
  kubectl -n $2 rollout status deployment/$1 --timeout=1m || true
}

prepare $namespace

for chart in ${REPO_ROOT}/stable/appmesh*/; do
  echo "Installing $chart"
  install $chart $namespace
  waitForDeploy $chart $namespace
done

