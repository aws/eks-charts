#!/usr/bin/env bash

# Run e2e tests

set -o errexit

export REPO_ROOT=$(git rev-parse --show-toplevel)
export PATH="$REPO_ROOT/build/tools:$PATH"

cd "${REPO_ROOT}/test/e2e/"
bats -t .
