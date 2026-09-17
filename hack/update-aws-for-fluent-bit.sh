#!/usr/bin/env bash
set -euo pipefail

# This script requires yq >= v4 and the GitHub CLI (gh).
# Bumps stable/aws-for-fluent-bit to the latest release of aws/aws-for-fluent-bit.
# A major image bump increments the chart minor version (as in #1294); anything else increments the chart patch.

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CHART_DIRECTORY="${PROJECT_ROOT}/stable/aws-for-fluent-bit"
CHART_FILE="${CHART_DIRECTORY}/Chart.yaml"
VALUES_FILE="${CHART_DIRECTORY}/values.yaml"

# Releases are listed by date; sort -V picks the highest version even when an older line gets a backport.
LATEST=$(gh release list --repo aws/aws-for-fluent-bit --exclude-drafts --exclude-pre-releases --limit 50 --json tagName \
  --jq '.[].tagName | ltrimstr("v")' | sort -V | tail -n 1)
CURRENT=$(yq eval '.appVersion' "$CHART_FILE")

if [[ -z "$LATEST" ]]; then
  echo "Could not determine latest release" >&2
  exit 1
fi

if [[ "$LATEST" == "$(printf '%s\n%s\n' "$CURRENT" "$LATEST" | sort -V | head -n 1)" ]]; then
  echo "aws-for-fluent-bit already at ${CURRENT} (latest ${LATEST})"
  exit 0
fi

echo "Updating aws-for-fluent-bit ${CURRENT} -> ${LATEST}"
yq eval -i ".appVersion = \"${LATEST}\"" "$CHART_FILE"
# sed instead of yq: yq -i rewrites block scalars and comment indentation in values.yaml
sed "s/^  tag: ${CURRENT}\$/  tag: ${LATEST}/" "$VALUES_FILE" > "${VALUES_FILE}.tmp" && mv "${VALUES_FILE}.tmp" "$VALUES_FILE"

VERSION=$(yq eval '.version' "$CHART_FILE")
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
if [[ "${CURRENT%%.*}" != "${LATEST%%.*}" ]]; then
  NEW_VERSION="${MAJOR}.$((MINOR + 1)).0"
else
  NEW_VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
fi
yq eval -i ".version = \"${NEW_VERSION}\"" "$CHART_FILE"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "version=${LATEST}" >> "$GITHUB_OUTPUT"
fi
