#!/usr/bin/env bash
set -euo pipefail

# This script requires yq >= v4.52, install it here:
# https://github.com/mikefarah/yq/?tab=readme-ov-file#install

# Hard code just preview instance types or ones that may not show up in Describe responses.
# Each chart has its own list, since not every instance type is supported by every component.
EFA_DEVICE_PLUGIN_TYPES=(
  "p6e-gb300.36xlarge" "p6e-gb200.36xlarge"
  "trn2-ac.24xlarge" "trn2u-ac.24xlarge" "trn2u.48xlarge"
)
DRANET_TYPES=(
  "p6e-gb300.36xlarge" "p6e-gb200.36xlarge"
  "trn2-ac.24xlarge" "trn2u-ac.24xlarge" "trn2u.48xlarge"
  "trn3.48xlarge" "trn3-dev0.48xlarge" "trn3-dev1.48xlarge"
  "trn3p.48xlarge" "trn3pd98.48xlarge" "trn3s.48xlarge"
  "trn3en.24xlarge"
)

PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Get list of opted-in regions
mapfile -t REGIONS < <(
  aws ec2 describe-regions \
    --query 'Regions[?OptInStatus==`opt-in-not-required` || OptInStatus==`opted-in`].RegionName' \
    --output text \
  | tr '\t' '\n'
)

# Fetch instance types from each region once, shared by all charts
EC2_TYPES=()
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

  EC2_TYPES+=("${TYPES[@]}")
done

# update_chart <chart directory> <hard-coded type>...
# Writes EC2 types + the given hard-coded types to supportedInstanceLabels.values
# and bumps the chart patch version if the values changed.
update_chart() {
  local CHART_DIRECTORY="$1"
  shift
  echo "Updating ${CHART_DIRECTORY}"

  # Build a yq array, then deduplicate + sort with yq builtins
  local YQ_ARRAY
  YQ_ARRAY=$(printf -- '- %s\n' "$@" "${EC2_TYPES[@]}" | yq 'unique | sort')
  export YQ_ARRAY

  local VALUES_FILE="${CHART_DIRECTORY}/values.yaml"
  yq eval -i '.supportedInstanceLabels.values = env(YQ_ARRAY)' "$VALUES_FILE"

  local CHART_FILE="${CHART_DIRECTORY}/Chart.yaml"
  if ! git diff --quiet --exit-code -- "$VALUES_FILE" && \
     ! git diff "$CHART_FILE" | grep -q '^[-+]version:'; then
      # Increment patch version if version hasn't already been incremented.
      # Keep the chart's existing "v" prefix (or lack of one).
      local VERSION PREFIX="" MAJOR MINOR PATCH
      VERSION=$(yq eval '.version' "$CHART_FILE")
      [[ "$VERSION" == v* ]] && PREFIX="v"
      IFS='.' read -r MAJOR MINOR PATCH <<< "${VERSION#v}"
      yq eval -i ".version = \"${PREFIX}${MAJOR}.${MINOR}.$((PATCH + 1))\"" "$CHART_FILE"
  fi
}

update_chart "${PROJECT_ROOT}/stable/aws-efa-k8s-device-plugin" "${EFA_DEVICE_PLUGIN_TYPES[@]}"
update_chart "${PROJECT_ROOT}/stable/aws-dranet" "${DRANET_TYPES[@]}"
