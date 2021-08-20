#!/usr/bin/env bash
set -euo pipefail

PLATFORM=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$([[ $(uname -m) = "x86_64" ]] && echo 'amd64' || echo 'arm64')
GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
BUILD_DIR="${GIT_REPO_ROOT}/build"
TMP_DIR="${BUILD_DIR}/tmp"
TOOLS_DIR="${BUILD_DIR}/tools"
mkdir -p "${TOOLS_DIR}"
export PATH="${TOOLS_DIR}:${PATH}"

HELMV2_VERSION="v2.17.0"
HELMV3_VERSION="v3.6.3"
KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
KIND_VERSION=v0.11.1
BATS_VERSION=1.1.0

## Install kubectl
curl -sSL "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${PLATFORM}/${ARCH}/kubectl" -o "${TOOLS_DIR}/kubectl"
chmod +x "${TOOLS_DIR}/kubectl"

## Install kubeval
mkdir -p "${TMP_DIR}/kubeval"
curl -sSL https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-${PLATFORM}-${ARCH}.tar.gz | tar xz -C "${TMP_DIR}/kubeval"
mv "${TMP_DIR}/kubeval/kubeval" "${TOOLS_DIR}/kubeval"

## Install helm v2
mkdir -p "${TMP_DIR}/helmv2"
curl -sSL  https://get.helm.sh/helm-${HELMV2_VERSION}-${PLATFORM}-${ARCH}.tar.gz | tar xz -C "${TMP_DIR}/helmv2"
mv "${TMP_DIR}/helmv2/${PLATFORM}-${ARCH}/helm" "${TOOLS_DIR}/helmv2"
rm -rf "${PLATFORM}-${ARCH}"

## Install helm v3
mkdir -p "${TMP_DIR}/helmv3"
curl -sSL https://get.helm.sh/helm-${HELMV3_VERSION}-${PLATFORM}-${ARCH}.tar.gz | tar xz -C "${TMP_DIR}/helmv3"
mv "${TMP_DIR}/helmv3/${PLATFORM}-${ARCH}/helm" "${TOOLS_DIR}/helmv3"
rm -rf "${PLATFORM}-${ARCH}"

## Install Bats
curl -sSL https://github.com/bats-core/bats-core/archive/v${BATS_VERSION}.tar.gz | tar xz -C "${TOOLS_DIR}"
ln -s ${TOOLS_DIR}/bats-core-${BATS_VERSION}/bin/bats ${TOOLS_DIR}/bats

## Initialize helm

helmv2 init --stable-repo-url https://charts.helm.sh/stable --client-only --kubeconfig="${BUILD_DIR}/.kube/kubeconfig"


## Install kind
curl -sSL "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-${PLATFORM}-${ARCH}" -o "${TOOLS_DIR}/kind"
chmod +x "${TOOLS_DIR}/kind"

rm -rf ${TMP_DIR}
