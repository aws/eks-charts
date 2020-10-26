#!/usr/bin/env bash
set -euo pipefail

GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
BUILD_DIR="${GIT_REPO_ROOT}/build"
TOOLS_DIR="${BUILD_DIR}/tools"
STABLE="${GIT_REPO_ROOT}/stable"
export PATH="${TOOLS_DIR}:${PATH}"

RELEASE_NOTES="${BUILD_DIR}/release-notes.md"
touch "${RELEASE_NOTES}"

function get_chart_version() {
    chart="$(basename ${1})"
    grep 'version: [0-9]\+\.[0-9]\+\.[0-9]\+' "${GIT_REPO_ROOT}/stable/${chart}/Chart.yaml" | cut -d':' -f2 | tr -d '[:space:]'
}

function get_app_version() {
    chart="$(basename ${1})"
    grep 'appVersion:[ ]*v\?[0-9]\+\.[0-9]\+\.[0-9]\+' "${GIT_REPO_ROOT}/stable/${chart}/Chart.yaml" | cut -d':' -f2 | tr -d '[:space:]'
}

>&2 git fetch --all --tags

if $(git describe HEAD --tags | grep -Eq "^v[0-9]+(\.[0-9]+)*(-[a-z0-9]+)?$"); then
    LAST_RELEASE_HASH=$(git rev-list --tags --max-count=1 --skip=1 --no-walk)
else 
    TAG=$(git describe HEAD --tags | grep -Eo "^v[0-9]+(\.[0-9]+)*")
    LAST_RELEASE_HASH=$(git rev-list -1 $TAG)
fi
LAST_RELEASE_TAG=$(git describe $LAST_RELEASE_HASH --tags)

CHANGED_CHARTS=()

cd ${STABLE}
echo "## Charts" | tee "${RELEASE_NOTES}"
for chart in */; do
    chart="$(basename $chart)"
    LAST_COMMIT_HASH=$(git --no-pager log --pretty=tformat:"%H" -- "${chart}" | awk 'FNR <= 1')
    ## If LAST_RELEASE_HASH does not include the chart, then it's a new chart so we'll add it to the notes
    if [[ -z $(git ls-tree -d $LAST_RELEASE_HASH "${chart}") ]]; then
        echo "- ${chart} (chart $(get_chart_version ${chart}), image $(get_app_version ${chart}))"  | tee -a "${RELEASE_NOTES}"
        CHANGED_CHARTS+=("${chart}")
        continue
    fi
    ## If LAST_RELEASE_HASH is NOT an ancestor of LAST_COMMIT_HASH then it has not been modified 
    if [[ ! -z $LAST_COMMIT_HASH && -z $(git rev-list $LAST_COMMIT_HASH | grep $LAST_RELEASE_HASH) || $LAST_COMMIT_HASH == $LAST_RELEASE_HASH ]]; then
        continue
    fi
    ## The chart was modified since the last release
    echo "- ${chart} (chart $(get_chart_version ${chart}), image $(get_app_version ${chart}))"  | tee -a "${RELEASE_NOTES}"
    CHANGED_CHARTS+=("${chart}")
done

echo "## Changes"  | tee -a "${RELEASE_NOTES}"
for chart in "${CHANGED_CHARTS[@]}"; do
    echo "- [${chart}]" | tee -a "${RELEASE_NOTES}"
    for change in $(git rev-list $LAST_RELEASE_HASH..HEAD ${chart}); do
        one_line_msg=$(git --no-pager log --pretty='%s (thanks to %an)'  "${change}" -n1 |  sed 's/^\[.*\]//' | xargs)
        echo "  - ${one_line_msg}" | tee -a "${RELEASE_NOTES}"
    done
done

>&2 echo -e "\n\nRelease notes file: ${RELEASE_NOTES}"
