#!/usr/bin/env bash

# App Mesh charts smoke test

set -o errexit

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
export REPO_ROOT=$(git rev-parse --show-toplevel)

helmVersion=v2.14.3
namespace=appmesh-system

source ${REPO_ROOT}/test/lib/helm.sh

function prepare {
  infof "Preparing namespace $namespace"
  kubectl create ns $1
  kubectl apply -k ${REPO_ROOT}/stable/appmesh-controller/crds
}

function finish {
  infof "Printing container logs"
  kubectl -n $namespace logs -l app.kubernetes.io/part-of=appmesh || true

  infof "Listing pods"
  kubectl -n $namespace get pods || true
}
trap finish EXIT

installHelm $helmVersion

prepare $namespace

for chart in ${REPO_ROOT}/stable/appmesh*/; do
  installChart $chart $namespace
  waitForDeployment $chart $namespace
done

