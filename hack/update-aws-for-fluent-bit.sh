#!/usr/bin/env bash
set -euo pipefail

# This script requires yq >= v4 and the GitHub CLI (gh).
# Bumps stable/aws-for-fluent-bit to the latest 3.x release of aws/aws-for-fluent-bit.

PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CHART_DIRECTORY="${PROJECT_ROOT}/stable/aws-for-fluent-bit"
CHART_FILE="${CHART_DIRECTORY}/Chart.yaml"
VALUES_FILE="${CHART_DIRECTORY}/values.yaml"

# 2.x reached end of life on 2026-06-30; only track the 3.x line.
LATEST=$(gh release list --repo aws/aws-for-fluent-bit --exclude-drafts --exclude-pre-releases --limit 50 --json tagName \
  --jq '.[].tagName | ltrimstr("v") | select(startswith("3."))' | sort -V | tail -n 1)
CURRENT=$(yq eval '.appVersion' "$CHART_FILE")

if [[ -z "$LATEST" ]]; then
  echo "Could not determine latest 3.x release" >&2
  exit 1
fi

if [[ "$LATEST" == "$CURRENT" ]]; then
  echo "aws-for-fluent-bit already at ${CURRENT}"
  exit 0
fi

echo "Updating aws-for-fluent-bit ${CURRENT} -> ${LATEST}"
yq eval -i ".appVersion = \"${LATEST}\"" "$CHART_FILE"
# sed instead of yq: yq -i rewrites block scalars and comment indentation in values.yaml
sed "s/^  tag: ${CURRENT}\$/  tag: ${LATEST}/" "$VALUES_FILE" > "${VALUES_FILE}.tmp" && mv "${VALUES_FILE}.tmp" "$VALUES_FILE"

VERSION=$(yq eval '.version' "$CHART_FILE")
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
yq eval -i ".version = \"${MAJOR}.${MINOR}.$((PATCH + 1))\"" "$CHART_FILE"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "version=${LATEST}" >> "$GITHUB_OUTPUT"
fi
