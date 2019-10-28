#!/usr/bin/env bash

# Run e2e tests

set -o errexit

export REPO_ROOT=$(git rev-parse --show-toplevel)

cd "${REPO_ROOT}/test/e2e/"
/tmp/bin/bats -t .
