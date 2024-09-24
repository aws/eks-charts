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

HELM_VERSION="v3.16.1"
KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
KIND_VERSION=v0.24.0
BATS_VERSION=1.11.0

## Install kubectl
curl -sSL "https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/${PLATFORM}/${ARCH}/kubectl" -o "${TOOLS_DIR}/kubectl"
chmod +x "${TOOLS_DIR}/kubectl"

## Install kubeval
mkdir -p "${TMP_DIR}/kubeval"
curl -sSL https://github.com/instrumenta/kubeval/releases/latest/download/kubeval-${PLATFORM}-${ARCH}.tar.gz | tar xz -C "${TMP_DIR}/kubeval"
mv "${TMP_DIR}/kubeval/kubeval" "${TOOLS_DIR}/kubeval"

## Install helm
mkdir -p "${TMP_DIR}/helm"
curl -sSL https://get.helm.sh/helm-${HELM_VERSION}-${PLATFORM}-${ARCH}.tar.gz | tar xz -C "${TMP_DIR}/helm"
mv "${TMP_DIR}/helm/${PLATFORM}-${ARCH}/helm" "${TOOLS_DIR}/helm"
rm -rf "${PLATFORM}-${ARCH}"

## Install Bats
curl -sSL https://github.com/bats-core/bats-core/archive/v${BATS_VERSION}.tar.gz | tar xz -C "${TOOLS_DIR}"
ln -s ${TOOLS_DIR}/bats-core-${BATS_VERSION}/bin/bats ${TOOLS_DIR}/bats

## Install kind
curl -sSL "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-${PLATFORM}-${ARCH}" -o "${TOOLS_DIR}/kind"
chmod +x "${TOOLS_DIR}/kind"

rm -rf ${TMP_DIR}
