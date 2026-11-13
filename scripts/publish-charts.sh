#!/usr/bin/env bash
set -euo pipefail
set -x

GIT_REPO_ROOT=$(git rev-parse --show-toplevel)
BUILD_DIR="${GIT_REPO_ROOT}/build"
TOOLS_DIR="${BUILD_DIR}/tools"
STABLE="${GIT_REPO_ROOT}/stable"
PACKAGE_DIR="${GIT_REPO_ROOT}/build"
export PATH="${TOOLS_DIR}:${PATH}"
VERSION="$(git describe --tags --always)"

if echo "${VERSION}" | grep -Eq "^v[0-9]+(\.[0-9]+){2}$"; then
    git fetch --all
    git config user.email eks-bot@users.noreply.github.com
    git config user.name eks-bot
    # Don't leak GITHUB_TOKEN
    set +x
    git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}
    set -x
    git config pull.rebase false
    git checkout gh-pages
    # Index only packages that are not published yet and merge the existing index into the result.
    # Re-indexing the whole gh-pages directory would rebuild every entry and reset all "created"
    # timestamps to the current time. Already published packages are never overwritten.
    NEW_PACKAGES_DIR="$(mktemp -d)"
    for pkg in "${PACKAGE_DIR}"/stable/*.tgz; do
        if [[ -e "${pkg}" && ! -e "$(basename "${pkg}")" ]]; then
            mv "${pkg}" "${NEW_PACKAGES_DIR}/"
        fi
    done
    helm repo index "${NEW_PACKAGES_DIR}" --url https://aws.github.io/eks-charts --merge index.yaml
    find "${NEW_PACKAGES_DIR}" -maxdepth 1 -name '*.tgz' -exec mv {} . \;
    mv "${NEW_PACKAGES_DIR}/index.yaml" index.yaml
    git add .
    git commit -m "Publish stable charts ${VERSION}"
    git push origin gh-pages
    echo "✅ Published charts"
else
    echo "Not a valid semver release tag! Skip charts publish"
    exit 1
fi

