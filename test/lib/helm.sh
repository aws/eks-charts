#!/usr/bin/env bash

# Helm charts testing helpers

set -o errexit

export REPO_ROOT=$(git rev-parse --show-toplevel)

function infof() {
    echo -e "\e[32m${1}\e[0m" >&3
}

function errorf() {
    echo -e "\e[31m${1}\e[0m" >&3
    exit 1
}

function installChart() {
  chartName=$(basename $1)
  testValues="$1/ci/values.yaml"

  infof "Installing chart $chartName"
  if test -f "$testValues"; then
    helm upgrade -i $chartName $1 --namespace $2 -f $testValues
  else
    helm upgrade -i $chartName $1 --namespace $2
  fi
  infof "✔ $chartName chart install test passed"
}

function waitForDeployment() {
  chartName=$(basename $1)
  infof "Waiting for deployment $chartName"
  retries=10
  count=0
  ok=false
  until $ok; do
    kubectl -n $2 get deployment/$chartName && ok=true || ok=false
    sleep 6
    count=$(($count + 1))
    if [[ $count -eq $retries ]]; then
      errorf "No more retries left"
    fi
  done

  kubectl -n $2 rollout status deployment/$chartName --timeout=1m >&3
  infof "✔ deployment/$chartName test passed"
}

function waitForService() {
  chartName=$(basename $1)
  infof "Waiting for service $chartName"
  retries=10
  count=0
  ok=false
  until $ok; do
    kubectl -n $2 get svc/$chartName && ok=true || ok=false
    sleep 6
    count=$(($count + 1))
    if [[ $count -eq $retries ]]; then
      errorf "No more retries left"
    fi
  done
    infof "✔ service/$chartName test passed"
}
