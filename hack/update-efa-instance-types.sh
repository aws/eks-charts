#!/usr/bin/env bash
set -euo pipefail

# This script requires yq >= v4, install it here:
# https://github.com/mikefarah/yq/?tab=readme-ov-file#install

PROJECT_ROOT=$(git rev-parse --show-toplevel)
EFA_CHART_DIRECTORY="${PROJECT_ROOT}/stable/aws-efa-k8s-device-plugin"

CHART_FILE="${EFA_CHART_DIRECTORY}/Chart.yaml"
if git diff --quiet --exit-code -- "$CHART_FILE" || \
   ! git diff "$CHART_FILE" | grep -q '^[-+]version:'; then
    # Increment a minor version if version hasn't already been incremented
    yq -i '
      .version |= (
        . as $v
        | ($v | sub("^v"; "") | split(".") | .[2] = ((.[2] | tonumber) + 1) | "v" + (join(".")))
      )
    ' "$CHART_FILE"
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

# Deduplicate + sort + extract JSON
export NEW_VALUES=$(printf "%s\n" "${ALL_TYPES[@]}" \
  | sort -u \
  | jq -R . \
  | jq -s .)

yq 'env(NEW_VALUES)' <<< '{}'

yq -i '.supportedInstanceLabels.values = env(NEW_VALUES) 
       | .supportedInstanceLabels.values style=""
       | .supportedInstanceLabels.values[] style=""' "${EFA_CHART_DIRECTORY}/values.yaml"