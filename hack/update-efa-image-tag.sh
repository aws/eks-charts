#!/usr/bin/env bash
set -euo pipefail

# This script requires yq >= v4.52, install it here:
# https://github.com/mikefarah/yq/?tab=readme-ov-file#install
# It also needs jq and GNU coreutils (sort -V, sed -i).

# Updates the EFA device plugin chart to the newest image tag available in the
# EKS registry, so a rebuilt image reaches chart consumers without a manual bump.
#
# Accepted tag shapes are `vX.Y.Z` and `vX.Y.Z-eksbuild.N`. Per-arch tags
# (`-linux_amd64`) and pre-release artifacts (`-test-eksbuild.N`) are ignored.
#
# A tag is only adopted once it resolves in every region of READINESS_REGIONS,
# serving both amd64 and arm64, since a tag can be available in one region before
# another. A change to the `vX.Y.Z` base is a plugin upgrade rather than a
# rebuild, so it bumps the chart's minor version instead of its patch.
#
# The tag is never moved backwards. Nothing is written when there is nothing new,
# and the script exits non-zero rather than silently doing nothing if the
# registry cannot be read or the chart is in an unexpected state.

PROJECT_ROOT=$(git rev-parse --show-toplevel)
EFA_CHART_DIRECTORY="${PROJECT_ROOT}/stable/aws-efa-k8s-device-plugin"
VALUES_FILE="${EFA_CHART_DIRECTORY}/values.yaml"
CHART_FILE="${EFA_CHART_DIRECTORY}/Chart.yaml"
README_FILE="${EFA_CHART_DIRECTORY}/README.md"

# Sampled alongside the registry's own region. Commercial partition only, which
# is also all the repository parser below accepts.
EXTRA_READINESS_REGIONS=("us-east-1" "eu-west-1" "ap-southeast-1")

# How far back to walk when the newest tags are not usable yet. Older tags would
# lose to the downgrade guard anyway.
MAX_CANDIDATES=10

TAG_PATTERN='^v[0-9]+\.[0-9]+\.[0-9]+(-eksbuild\.[0-9]+)?$'

MANIFEST_INDEX_TYPES=(
  "application/vnd.docker.distribution.manifest.list.v2+json"
  "application/vnd.oci.image.index.v1+json"
)
MANIFEST_TYPES=(
  "application/vnd.docker.distribution.manifest.v2+json"
  "application/vnd.oci.image.manifest.v1+json"
)

# Entries an index carries for attestations and similar have platform
# architecture "unknown" or none at all, and are not images to be pulled. Keep
# the parentheses: `//` binds looser than `!=`, so without them this selects
# `.platform.architecture // false`, which keeps the entries it means to drop.
PLATFORM_MANIFESTS='.manifests[]? | select((.platform.architecture // "unknown") != "unknown")'

# GitHub Actions renders these as annotations on the run summary, which requires
# stdout; they are ordinary output everywhere else. Functions that log never
# return data through stdout, so an annotation can never be captured as a value.
log_error() { echo "::error::$*"; }
log_warning() { echo "::warning::$*"; }

# Strips the -eksbuild.N suffix, leaving the upstream plugin version.
base_version() { printf '%s' "${1%-eksbuild.*}"; }

# Echoes the greater of two version strings.
newer_version() { printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1; }

STDERR_CAPTURE=$(mktemp)
trap 'rm -f "$STDERR_CAPTURE"' EXIT

# Candidates that could not be evaluated, as opposed to ones that are simply not
# available yet. Adopting nothing while this is non-zero is not a result, so the
# script fails instead of exiting 0. Only consulted when nothing was adopted.
EVALUATION_ERRORS=0

# Why a candidate was rejected for a reason that will not resolve on its own,
# carried into the summary. Names the tag, since the summary is read alone.
STALL_REASON=""

# Captured stderr as a single line. ARNs are redacted because AWS error messages
# embed the calling identity and this runs in a public repository's logs.
captured_stderr() {
  tr '\n' ' ' <"$STDERR_CAPTURE" \
    | sed -E 's#arn:aws[^[:space:]]*#<arn>#g; s/^[[:space:]]+//; s/[[:space:]]+$//'
}

# Read the image coordinates off the chart so they are not duplicated here.
# e.g. 602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/aws-efa-k8s-device-plugin
REPOSITORY=$(yq eval '.image.repository' "$VALUES_FILE")
CURRENT_TAG=$(yq eval '.image.tag' "$VALUES_FILE")

if [[ ! "$REPOSITORY" =~ ^([0-9]{12})\.dkr\.ecr\.([a-z0-9-]+)\.amazonaws\.com/(.+)$ ]]; then
  log_error "cannot parse .image.repository from ${VALUES_FILE}: ${REPOSITORY}"
  exit 1
fi
REGISTRY_ID="${BASH_REMATCH[1]}"
HOME_REGION="${BASH_REMATCH[2]}"
ECR_REPOSITORY="${BASH_REMATCH[3]}"

# An unparseable pinned tag means a human changed something this script should
# not reason about, and it is also spliced into the README substitution below.
if [[ ! "$CURRENT_TAG" =~ $TAG_PATTERN ]]; then
  log_error "unexpected .image.tag in ${VALUES_FILE}: '${CURRENT_TAG}'"
  exit 1
fi

READINESS_REGIONS=("$HOME_REGION" "${EXTRA_READINESS_REGIONS[@]}")

echo "Chart is on ${CURRENT_TAG}"
echo "Listing tags in ${REGISTRY_ID}/${ECR_REPOSITORY} (${HOME_REGION})"

# Kept out of a pipeline into mapfile: process substitution hides the exit
# status, which would turn "the registry rejected us" into "there is nothing to
# update" and exit 0.
if ! TAG_LISTING=$(aws ecr list-images \
      --registry-id "$REGISTRY_ID" \
      --repository-name "$ECR_REPOSITORY" \
      --region "$HOME_REGION" \
      --query 'imageIds[].imageTag' \
      --output text 2>"$STDERR_CAPTURE"); then
  log_error "failed to list tags in ${ECR_REPOSITORY} (${HOME_REGION}): $(captured_stderr)"
  exit 1
fi

# Oldest first, so the readiness walk below can start from the newest.
mapfile -t ALL_TAGS < <(
  printf '%s\n' "$TAG_LISTING" \
  | tr '\t' '\n' \
  | grep -E "$TAG_PATTERN" \
  | sort -V -u
)

if [ "${#ALL_TAGS[@]}" -eq 0 ]; then
  log_error "no tags matching ${TAG_PATTERN} in ${ECR_REPOSITORY}; the tagging convention may have changed"
  exit 1
fi

CURRENT_BASE=$(base_version "$CURRENT_TAG")

# Newest tags first in the walk below, across every plugin version.
mapfile -t CANDIDATE_TAGS < <(printf '%s\n' "${ALL_TAGS[@]}" | tail -n "$MAX_CANDIDATES")

# Sets MANIFEST_BODY and MANIFEST_DIGEST on success. Returns 1 when the manifest
# evaluated, which increments EVALUATION_ERRORS, and 2 when the registry answered
# but the image is not there. Callers treat both as "not usable".
MANIFEST_BODY=""
MANIFEST_DIGEST=""
fetch_manifest() {
  local region=$1 image_id=$2
  shift 2
  local response

  MANIFEST_BODY=""
  MANIFEST_DIGEST=""

  if ! response=$(aws ecr batch-get-image \
        --registry-id "$REGISTRY_ID" \
        --repository-name "$ECR_REPOSITORY" \
        --region "$region" \
        --image-ids "$image_id" \
        --accepted-media-types "$@" \
        --output json 2>"$STDERR_CAPTURE"); then
    log_warning "batch-get-image failed in ${region} for ${image_id}: $(captured_stderr)"
    EVALUATION_ERRORS=$((EVALUATION_ERRORS + 1))
    return 1
  fi

  # A missing image is reported as a 200 with a failures[] entry, not an error.
  if ! MANIFEST_BODY=$(jq -r '.images[0].imageManifest // empty' <<<"$response"); then
    log_warning "unparseable batch-get-image response in ${region} for ${image_id}"
    EVALUATION_ERRORS=$((EVALUATION_ERRORS + 1))
    return 1
  fi

  [ -n "$MANIFEST_BODY" ] || return 2
  MANIFEST_DIGEST=$(jq -r '.images[0].imageId.imageDigest // empty' <<<"$response")
}

# Succeeds when the tag is safe to pin: an index advertising both architectures
# whose platform manifests are all present in every sampled region.
tag_is_ready() {
  local tag=$1
  local index index_digest arches region digest want rc
  local -a digests

  rc=0
  fetch_manifest "$HOME_REGION" "imageTag=${tag}" "${MANIFEST_INDEX_TYPES[@]}" || rc=$?
  if [ "$rc" -ne 0 ]; then
    [ "$rc" -eq 2 ] && echo "  ${tag}: no manifest index in ${HOME_REGION}"
    return 1
  fi
  # These are overwritten by the fetches in the region loop below.
  index="$MANIFEST_BODY"
  index_digest="$MANIFEST_DIGEST"

  if ! arches=$(jq -r "[${PLATFORM_MANIFESTS} | .platform.architecture] | unique | join(\" \")" <<<"$index"); then
    log_warning "could not read platforms from the ${tag} index"
    EVALUATION_ERRORS=$((EVALUATION_ERRORS + 1))
    return 1
  fi

  # A single-arch index will not become multi-arch later, so report the reason
  # rather than letting it read as a tag that is not available yet.
  for want in amd64 arm64; do
    if ! grep -qw -- "$want" <<<"$arches"; then
      STALL_REASON="${tag}: index does not serve ${want} (has: ${arches:-none})"
      echo "  ${STALL_REASON}"
      return 1
    fi
  done

  mapfile -t digests < <(jq -r "${PLATFORM_MANIFESTS} | .digest" <<<"$index")
  if [ "${#digests[@]}" -eq 0 ]; then
    STALL_REASON="${tag}: index lists no platform manifests"
    echo "  ${STALL_REASON}"
    return 1
  fi

  for region in "${READINESS_REGIONS[@]}"; do
    # The home region's index is already in hand from the fetch above.
    if [ "$region" != "$HOME_REGION" ]; then
      rc=0
      fetch_manifest "$region" "imageTag=${tag}" "${MANIFEST_INDEX_TYPES[@]}" || rc=$?
      if [ "$rc" -ne 0 ]; then
        [ "$rc" -eq 2 ] && echo "  ${tag}: index is not in ${region} yet"
        return 1
      fi
      # Otherwise the tag could point at an older index in this region while the
      # children of the newer one happen to be present.
      if [ "$MANIFEST_DIGEST" != "$index_digest" ]; then
        echo "  ${tag}: points at a different index in ${region} (${MANIFEST_DIGEST})"
        return 1
      fi
    fi

    for digest in "${digests[@]}"; do
      rc=0
      fetch_manifest "$region" "imageDigest=${digest}" "${MANIFEST_TYPES[@]}" || rc=$?
      if [ "$rc" -ne 0 ]; then
        [ "$rc" -eq 2 ] && echo "  ${tag}: ${digest} has not replicated to ${region} yet"
        return 1
      fi
    done
  done
}

NEW_TAG=""
for (( i=${#CANDIDATE_TAGS[@]}-1; i>=0; i-- )); do
  if tag_is_ready "${CANDIDATE_TAGS[i]}"; then
    NEW_TAG="${CANDIDATE_TAGS[i]}"
    break
  fi
done

if [ -z "$NEW_TAG" ]; then
  if [ "$EVALUATION_ERRORS" -gt 0 ]; then
    log_error "could not evaluate any candidate tag: ${EVALUATION_ERRORS} registry call(s) failed"
    exit 1
  fi
  log_warning "no adoptable tag found (${STALL_REASON:-still replicating}); leaving chart on ${CURRENT_TAG}"
  exit 0
fi

echo "Newest replicated tag is ${NEW_TAG}"

if [ "$NEW_TAG" == "$CURRENT_TAG" ]; then
  echo "Chart is already up to date"
  exit 0
fi

# Guards against a listing that omits the pinned tag, which would otherwise roll
# consumers onto an older image.
if [ "$(newer_version "$CURRENT_TAG" "$NEW_TAG")" != "$NEW_TAG" ]; then
  log_warning "${NEW_TAG} is older than the chart's ${CURRENT_TAG}, refusing to downgrade"
  exit 0
fi

echo "Updating chart from ${CURRENT_TAG} to ${NEW_TAG}"

# The README config table hardcodes the default tag. Assert it is in the state
# this script expects, so a substitution that matches nothing cannot pass for a
# documentation update.
if ! grep -qF -- "\`${CURRENT_TAG}\`" "$README_FILE"; then
  log_error "${README_FILE} does not document ${CURRENT_TAG}; refusing to guess which line to update"
  exit 1
fi

NEW_TAG="$NEW_TAG" yq eval -i '.image.tag = strenv(NEW_TAG) | .image.tag style="double"' "$VALUES_FILE"
NEW_TAG="$NEW_TAG" yq eval -i '.appVersion = strenv(NEW_TAG) | .appVersion style="double"' "$CHART_FILE"
sed -i "s|\`${CURRENT_TAG}\`|\`${NEW_TAG}\`|g" "$README_FILE"

NEW_BASE=$(base_version "$NEW_TAG")

# Computed from the committed version, so the result is the same whether or not
# update-efa-instance-types.sh already bumped it.
COMMITTED_VERSION=$(git show "HEAD:stable/aws-efa-k8s-device-plugin/Chart.yaml" | yq eval '.version' -)
BARE="${COMMITTED_VERSION#v}"
IFS='.' read -r MAJOR MINOR PATCH <<< "$BARE"

if [ "$NEW_BASE" != "$CURRENT_BASE" ]; then
    # A new plugin version can change behaviour, so do not advertise it as a
    # chart patch.
    NEW_VERSION="v${MAJOR}.$((MINOR + 1)).0"
    UPGRADE_NOTE="Upgrades the EFA device plugin from ${CURRENT_BASE} to ${NEW_BASE}, not just a rebuild of the same version. Please review the upstream changes between those releases."
    log_warning "$UPGRADE_NOTE"
    # Surfaces in the pull request body. Absent outside GitHub Actions.
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
      echo "upgrade_note=${UPGRADE_NOTE}" >>"$GITHUB_OUTPUT"
    fi
else
    NEW_VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
fi

NEW_VERSION="$NEW_VERSION" yq eval -i '.version = strenv(NEW_VERSION)' "$CHART_FILE"
echo "Chart version ${COMMITTED_VERSION} -> ${NEW_VERSION}"
