#!/usr/bin/env bash
set -euo pipefail

# This script requires yq >= v4, install it here:
# https://github.com/mikefarah/yq/?tab=readme-ov-file#install

PROJECT_ROOT=$(git rev-parse --show-toplevel)
EFA_CHART_DIRECTORY="${PROJECT_ROOT}/stable/aws-efa-k8s-device-plugin"

CHART_FILE="${EFA_CHART_DIRECTORY}/Chart.yaml"
if git diff --quiet --exit-code -- "$CHART_FILE" || \
   ! git diff "$CHART_FILE" | grep -q '^[-+]version:'; then
    # Increment patch version if version hasn't already been incremented
    VERSION=$(yq eval '.version' "$CHART_FILE")
    BARE="${VERSION#v}"
    IFS='.' read -r MAJOR MINOR PATCH <<< "$BARE"
    NEW_VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
    yq eval -i ".version = \"${NEW_VERSION}\"" "$CHART_FILE"
else
    echo "Version already changed; skipping increment"
fi

# Get list of opted-in regions
mapfile -t REGIONS < <(
  aws ec2 describe-regions \
    --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].RegionName' \
    --output text \
  | tr '\t' '\n'
)

# Hard code just preview instance types or ones that may not show up in Describe responses
ALL_TYPES=("p6e-gb200.36xlarge" "trn2-ac.24xlarge" "trn2u-ac.24xlarge" "trn2u.48xlarge")

# Fetch instance types from each region
for REGION in "${REGIONS[@]}"; do
  echo "Getting EFA instance types in $REGION"
  mapfile -t TYPES < <(
    aws ec2 describe-instance-types \
      --region "$REGION" \
      --filters "Name=network-info.efa-supported,Values=true" \
      --query 'InstanceTypes[*].InstanceType' \
      --output text \
    | tr '\t' '\n' \
    | sed '/^$/d')

  ALL_TYPES+=("${TYPES[@]}")
done

# Deduplicate + sort, then build a yq array expression
YQ_ARRAY=$(printf '%s\n' "${ALL_TYPES[@]}" | sort -u | sed 's/.*/"&"/' | paste -sd, -)

VALUES_FILE="${EFA_CHART_DIRECTORY}/values.yaml"
yq eval -i ".supportedInstanceLabels.values = [${YQ_ARRAY}]" "$VALUES_FILE"
