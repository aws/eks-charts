#!/usr/bin/env bash

# Helm charts testing helpers

set -o errexit

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"
export REPO_ROOT=$(git rev-parse --show-toplevel)

infof() {
    echo -e "\e[32m${1}\e[0m"
}

errorf() {
    echo -e "\e[31m${1}\e[0m"
    exit 1
}

function installHelm() {
  infof "Installing Helm $1"
  curl -sSL https://get.helm.sh/helm-${1}-linux-amd64.tar.gz | \
    tar xz && sudo mv linux-amd64/helm /usr/local/bin/ && rm -rf linux-amd64

  infof 'Installing Tiller'
  kubectl --namespace kube-system create sa tiller

  kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

  helm init --service-account tiller --upgrade --wait
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

  kubectl -n $2 rollout status deployment/$chartName --timeout=1m
}




