#!/usr/bin/env bash

# Create Kubernetes cluster with Kind

set -o errexit

REPO_ROOT=$(git rev-parse --show-toplevel)
HELM_MODE="${HELM_MODE:-v2}"

kind create cluster --wait 5m

function installHelm() {

  if [[ "${1}" == "v2" ]]; then
    kubectl --namespace kube-system create sa tiller

    kubectl create clusterrolebinding tiller-cluster-rule \
      --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

    helm init --stable-repo-url https://charts.helm.sh/stable --service-account tiller --upgrade --wait
  else
    mv $REPO_ROOT/build/helmv3 $REPO_ROOT/build/helm
  fi
}

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

installHelm $HELM_MODE

kubectl get pods --all-namespaces
