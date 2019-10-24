#!/usr/bin/env bash

# App Mesh charts smoke test

set -o errexit

REPO_ROOT=$(git rev-parse --show-toplevel)
export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

namespace=appmesh-system

function finish {
  echo ">>> Printing container logs"
  kubectl -n $namespace logs -l app.kubernetes.io/part-of=appmesh || true

  echo ">>> Listing pods"
  kubectl -n $namespace get pods || true
}
trap finish EXIT

function prepare {
  kubectl create ns $1
  kubectl apply -k ${REPO_ROOT}/stable/appmesh-controller/crds
}

function install {
  chartName=$(basename $1)
  testValues="$1/ci/values.yaml"

  if test -f "$testValues"; then
    helm upgrade -i $chartName $1 --namespace $2 -f $testValues
  else
    helm upgrade -i $chartName $1 --namespace $2
  fi
}

function waitForDeploy {
  chartName=$(basename $1)
  echo ">>> Waiting for deployment $chartName "
  retries=10
  count=0
  ok=false
  until $ok; do
    kubectl -n $2 get deployment/$chartName && ok=true || ok=false
    sleep 5
    count=$(($count + 1))
    if [[ $count -eq $retries ]]; then
      echo "No more retries left"
      exit 1
    fi
  done

  kubectl -n $2 rollout status deployment/$chartName --timeout=1m
}

echo ">>> Preparing namespace $namespace"
prepare $namespace

for chart in ${REPO_ROOT}/stable/appmesh*/; do
  echo ">>> Installing $chart"
  install $chart $namespace
  waitForDeploy $chart $namespace
done

