#!/usr/bin/env bash

# Create Kubernetes cluster with Kind

set -o errexit

REPO_ROOT=$(git rev-parse --show-toplevel)
KIND_VERSION=v0.5.1
HELM2_VERSION=v2.14.3
HELM3_VERSION=v3.0.0-beta.5

function installKubernetes() {
  echo ">>> Installing kubectl"
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  sudo mv kubectl /usr/local/bin/

  echo ">>> Installing kind $KIND_VERSION"
  curl -sSLo kind "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64"
  chmod +x kind
  sudo mv kind /usr/local/bin/kind

  echo ">>> Creating kind cluster"
  kind create cluster --wait 5m
}

function installHelm() {
  echo ">>> Installing Helm $HELM2_VERSION"
  curl -sSL https://get.helm.sh/helm-${HELM2_VERSION}-linux-amd64.tar.gz | \
    tar xz && sudo mv linux-amd64/helm /usr/local/bin/ && rm -rf linux-amd64

  kubectl --namespace kube-system create sa tiller

  kubectl create clusterrolebinding tiller-cluster-rule \
    --clusterrole=cluster-admin --serviceaccount=kube-system:tiller

  helm init --service-account tiller --upgrade --wait

  echo ">>> Installing Helm $HELM3_VERSION"
  curl -sSL https://get.helm.sh/helm-${HELM3_VERSION}-linux-amd64.tar.gz | \
    tar xz && sudo mv linux-amd64/helm /bin/helmv3 && sudo rm -rf linux-amd64
}

installKubernetes

export KUBECONFIG="$(kind get kubeconfig-path --name="kind")"

installHelm

kubectl get pods --all-namespaces