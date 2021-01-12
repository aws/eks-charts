#!/usr/bin/env bash
set -euo pipefail

GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
BUILD_DIR="${GIT_REPO_ROOT}/build"
TOOLS_DIR="${BUILD_DIR}/tools"
STABLE="${GIT_REPO_ROOT}/stable"
export PATH="${TOOLS_DIR}:${PATH}"

EXIT_CODE=0
if $(git describe HEAD --tags | grep -Eq "^v[0-9]+(\.[0-9]+)*(-[a-z0-9]+)?$"); then
    LAST_RELEASE_HASH=$(git rev-list --tags --max-count=1 --skip=1 --no-walk)
else 
    TAG=$(git describe HEAD --tags | grep -Eo "^v[0-9]+(\.[0-9]+)*")
    LAST_RELEASE_HASH=$(git rev-list -1 $TAG)
fi
LAST_RELEASE_TAG=$(git describe $LAST_RELEASE_HASH --tags)
cd ${STABLE}
echo "📝 Checking for updated Chart versions since the last eks-charts release $LAST_RELEASE_TAG"
for d in */; do
    LAST_COMMIT_HASH=$(git --no-pager log --pretty=tformat:"%H" -- $d | awk 'FNR <= 1')
    ## If LAST_RELEASE_HASH does not include the chart, then it's a new chart and does not need a version increment
    if [[ -z $(git ls-tree -d $LAST_RELEASE_HASH $d) ]]; then
    echo "✅ Chart $d is a new chart since the last release"
    continue
    fi
    ## If LAST_RELEASE_HASH is NOT an ancestor of LAST_COMMIT_HASH then it has not been modified 
    if [[ ! -z $LAST_COMMIT_HASH && -z $(git rev-list $LAST_COMMIT_HASH | grep $LAST_RELEASE_HASH) || $LAST_COMMIT_HASH == $LAST_RELEASE_HASH ]]; then
    echo "✅ Chart $d had no changes since the last eks-charts release"
    continue
    fi
    LAST_RELEASE_CHART_VERSION=$(git --no-pager show $LAST_RELEASE_HASH:stable/"$d"Chart.yaml | grep 'version:' | xargs | cut -d' ' -f2 | tr -d '[:space:]')
    LAST_COMMIT_CHART_VERSION=$(git --no-pager show $LAST_COMMIT_HASH:stable/"$d"Chart.yaml | grep 'version:' | xargs | cut -d' ' -f2 | tr -d '[:space:]')
    if [[ $LAST_RELEASE_CHART_VERSION == $LAST_COMMIT_CHART_VERSION ]]; then
    echo "❌ Chart $d has the same Chart version as the last release $LAST_COMMIT_CHART_VERSION"
    EXIT_CODE=1
    else 
    echo "✅ Chart $d has a different version since the last eks-charts release ($LAST_RELEASE_CHART_VERSION -> $LAST_COMMIT_CHART_VERSION)"
    fi
done
exit $EXIT_CODE
