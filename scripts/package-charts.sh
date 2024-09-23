#!/usr/bin/env bash
set -euo pipefail

GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
BUILD_DIR="${GIT_REPO_ROOT}/build"
TOOLS_DIR="${BUILD_DIR}/tools"
STABLE="${GIT_REPO_ROOT}/stable"
export PATH="${TOOLS_DIR}:${PATH}"

PACKAGE_DIR="${GIT_REPO_ROOT}/build"
mkdir -p "${PACKAGE_DIR}"

helm package "${STABLE}/"* --destination "${PACKAGE_DIR}/stable" --dependency-update
