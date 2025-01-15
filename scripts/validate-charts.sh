#!/usr/bin/env bash
set -euo pipefail

GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
BUILD_DIR="${GIT_REPO_ROOT}/build"
TOOLS_DIR="${BUILD_DIR}/tools"
STABLE="${GIT_REPO_ROOT}/stable"
export PATH="${TOOLS_DIR}:${PATH}"

FAILED=()

cd ${STABLE}
for d in */; do
    EXTRA_ARGS=""
    if [ -f ${STABLE}/${d}/ci/extra_args ]; then
        EXTRA_ARGS=$(cat ${STABLE}/${d}/ci/extra_args)
    fi
    echo "Validating chart ${d} w/ helm"
    helm template ${STABLE}/${d} ${EXTRA_ARGS}| kubeval --strict --ignore-missing-schemas || FAILED+=("${d}")
done

if [[ "${#FAILED[@]}" -eq 0 ]]; then
    echo "All charts passed validations!"
    exit 0
else
    echo "Helm validation failed:"
    for chart in "${FAILED[@]}"; do
        printf "%40s ❌\n" "$chart"
    done
fi
