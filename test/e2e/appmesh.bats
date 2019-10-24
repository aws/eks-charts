#!/usr/bin/env bats

# App Mesh charts e2e test

set -o errexit

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
export REPO_ROOT=$(git rev-parse --show-toplevel)

namespace=appmesh-system
charts=${REPO_ROOT}/stable

load ${REPO_ROOT}/test/lib/helm.sh

function setup() {
  infof "Preparing namespace $namespace"
  kubectl create ns $namespace >&3
  kubectl apply -k ${REPO_ROOT}/stable/appmesh-controller/crds >&3
}

@test "App Mesh" {
  chart=$charts/appmesh-controller
  installChart $chart $namespace
  waitForDeployment $chart $namespace

  chart=$charts/appmesh-inject
  installChart $chart $namespace
  waitForDeployment $chart $namespace
  waitForService $chart $namespace

  chart=$charts/appmesh-prometheus
  installChart $chart $namespace
  waitForDeployment $chart $namespace
  waitForService $chart $namespace

  chart=$charts/appmesh-jaeger
  installChart $chart $namespace
  waitForDeployment $chart $namespace
  waitForService $chart $namespace
}

function teardown() {
  infof "Printing container logs"
  kubectl -n $namespace logs -l app.kubernetes.io/part-of=appmesh >&3 || true

  infof "Listing pods"
  kubectl -n $namespace get pods >&3 || true
}
