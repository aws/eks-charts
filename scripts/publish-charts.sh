#!/usr/bin/env bash
set -euo pipefail

GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
BUILD_DIR="${GIT_REPO_ROOT}/build"
TOOLS_DIR="${BUILD_DIR}/tools"
STABLE="${GIT_REPO_ROOT}/stable"
PACKAGE_DIR="${GIT_REPO_ROOT}/build"
export PATH="${TOOLS_DIR}:${PATH}"

if echo "${CIRCLE_TAG}" | grep -Eq "^v[0-9]+(\.[0-9]+){2}$"; then
    REPOSITORY="https://eks-bot:${GITHUB_TOKEN}@github.com/aws/eks-charts.git"
    git config user.email eks-bot@users.noreply.github.com
    git config user.name eks-bot
    git remote set-url origin ${REPOSITORY}
    git checkout gh-pages
    mv -f $PACKAGE_DIR/stable/*.tgz .
    helm repo index . --url https://aws.github.io/eks-charts
    git add .
    git commit -m "Publish stable charts ${CIRCLE_TAG}"
    git push origin gh-pages
    echo "✅ Published charts"
else
    echo "Not a valid semver release tag! Skip charts publish"
    # Need to exit 0 here since circle ci runs this everytime
    exit 0
fi
 