#!/usr/bin/env bash
set -euo pipefail

# This script requires yq >= v4.52, install it here:
# https://github.com/mikefarah/yq/?tab=readme-ov-file#install
# It also needs jq and GNU coreutils (sort -V, sed -i).

# Points the EFA device plugin chart at the newest usable image tag in the EKS
# registry, so neither a rebuild nor a new plugin version waits on someone to
# remember a manual bump. The chart's version bump and the pull request body say
# which of the two it was.
#
# Accepted tag shapes are `vX.Y.Z` and `vX.Y.Z-eksbuild.N`. Per-arch tags
# (`-linux_amd64`) and pre-release artifacts (`-test-eksbuild.N`) are ignored.
#
# A tag is only adopted once it resolves in every region of READINESS_REGIONS,
# serving both linux/amd64 and linux/arm64, since a tag can be available in one
# region before another. A change to the `vX.Y.Z` base is a plugin upgrade rather
# than a rebuild, so it bumps the chart's minor version instead of its patch.
#
# Only tags newer than the pinned one are considered, so the tag cannot move
# backwards. Nothing is written when there is nothing new. The script exits
# non-zero rather than silently doing nothing when it cannot establish an answer:
# the registry cannot be read, the chart's three copies of the tag disagree, or a
# candidate could not be evaluated. A condition it CAN establish, such as the
# pinned tag having been deleted, is reported through stall_note instead, which
# reddens the workflow run and names the cause in the pull request body.

PROJECT_ROOT=$(git rev-parse --show-toplevel)
EFA_CHART_DIRECTORY="${PROJECT_ROOT}/stable/aws-efa-k8s-device-plugin"
VALUES_FILE="${EFA_CHART_DIRECTORY}/values.yaml"
CHART_FILE="${EFA_CHART_DIRECTORY}/Chart.yaml"
README_FILE="${EFA_CHART_DIRECTORY}/README.md"

# Sampled alongside the registry's own region. Commercial partition only, which
# is also all the repository parser below accepts.
EXTRA_READINESS_REGIONS=("us-east-1" "eu-west-1" "ap-southeast-1")

TAG_PATTERN='^v[0-9]+\.[0-9]+\.[0-9]+(-eksbuild\.[0-9]+)?$'

MANIFEST_INDEX_TYPES=(
  "application/vnd.docker.distribution.manifest.list.v2+json"
  "application/vnd.oci.image.index.v1+json"
)
MANIFEST_TYPES=(
  "application/vnd.docker.distribution.manifest.v2+json"
  "application/vnd.oci.image.manifest.v1+json"
)

# Index entries a Linux EKS node could actually pull. Everything an index can
# carry that a node cannot use is excluded here rather than downstream:
#   - attestations and similar, which declare unknown/unknown or no platform, and
#     are caught by the os clause before the architecture one sees them (that
#     architecture clause is redundant with the variant clause's `else false`,
#     and is kept only as a guard against that being loosened)
#   - other operating systems, so a Windows amd64 entry cannot stand in for the
#     Linux amd64 one the chart needs
#   - a CPU variant the node's platform matcher will not accept. containerd
#     compares the NORMALISED triple by equality, and its normalisation folds
#     arm64 "8"/"v8"/"v8.0" and amd64 "v1" to the empty variant, so those are the
#     only spellings besides absent that match a default node. Anything else
#     (arm64 v7 or v9 or v8.2, amd64 v2 or v3, or amd64 carrying v8) does not.
#   - a malformed entry with no digest, or one that is not a sha256 digest, which
#     is the only kind ECR's imageDigest accepts
# Keep every `//` parenthesised: it binds looser than the comparisons, so
# `.platform.os // "" == "linux"` would parse as `.platform.os // ("" == "linux")`
# and select on a truthy string instead of comparing it.
# shellcheck disable=SC2016  # $v is a jq variable, not a shell one
PLATFORM_MANIFESTS='.manifests[]?
  | select(
      (.platform.os // "") == "linux"
      and (.platform.architecture // "unknown") != "unknown"
      and (
        ((.platform.variant // "") | ascii_downcase) as $v
        | if .platform.architecture == "arm64" then $v | IN("", "8", "v8", "v8.0")
          elif .platform.architecture == "amd64" then $v | IN("", "v1")
          else false end
      )
      and ((.digest // "") | startswith("sha256:"))
    )'

# Every platform the index offers, usable or not. The message below reports both,
# because the usable list is post-filter: an arm64/v7 entry reads as "does not
# serve linux/arm64", which contradicts what the registry plainly shows unless the
# offered list is there to explain it.
OFFERED_PLATFORMS='[.manifests[]?
  | select(.platform)
  | (.platform.os // "?") + "/" + (.platform.architecture // "?")
    + (if (.platform.variant // "") == "" then "" else "/" + .platform.variant end)
  ] | unique | join(" ")'

# GitHub Actions renders these as annotations on the run summary, which requires
# stdout; they are ordinary output everywhere else. Functions that log never
# return data through stdout, so an annotation can never be captured as a value.
log_error() { echo "::error::$*"; }
log_warning() { echo "::warning::$*"; }

# Strips the -eksbuild.N suffix, leaving the upstream plugin version.
base_version() { printf '%s' "${1%-eksbuild.*}"; }

STDERR_CAPTURE=$(mktemp)
trap 'rm -f "$STDERR_CAPTURE"' EXIT

# Candidates that could not be evaluated, as opposed to ones that are simply not
# available yet. Any outcome reached while this is non-zero is untrustworthy, so
# the script fails rather than reporting it.
EVALUATION_ERRORS=0

# Why a candidate was rejected for a reason that will not resolve on its own,
# carried into the summary. Names the tag, since the summary is read alone. Set
# only when the NEWEST rejected candidate was rejected permanently: if the newest
# is merely waiting on replication, waiting is the correct action even when an
# older candidate is broken, and calling for a human then would cry wolf daily
# until the newest replicates. Also set when the pinned tag itself has gone
# missing, which outranks any candidate because the chart already points somewhere
# bad and no amount of waiting fixes that.
STALL_REASON=""

# Set when the pinned tag is absent from the listing and the probe that would have
# settled whether it still exists could not complete. Harmless once a newer tag is
# adopted; fatal otherwise, because then nothing has verified the image the chart
# points at.
PIN_PROBE_FAILED=false

# Set when the pinned tag is absent from the listing but the registry still
# resolves it, which proves the listing under-reported and so may be missing newer
# tags too. Same shape as PIN_PROBE_FAILED: harmless once a tag is adopted, because
# each candidate is verified individually, and fatal otherwise, because "nothing
# newer" would be a conclusion drawn from a set known to be incomplete.
LISTING_INCOMPLETE=false

# Whether anything has been rejected yet, and if so what kind. The walk runs
# newest first, so the first write describes the newest rejected candidate, unless
# the missing-pin check below pre-seeds it. Only emptiness is ever consulted; the
# two values are there to say which branch wrote it.
FIRST_REJECTION=""

# A rejection that will not resolve on its own, so it needs a human.
reject_permanent() {
  echo "  $1"
  if [ -z "$FIRST_REJECTION" ]; then
    FIRST_REJECTION=permanent
    STALL_REASON="$1"
  fi
}

# A rejection that the next run may not see, so it needs only patience.
reject_pending() {
  echo "  $1"
  : "${FIRST_REJECTION:=pending}"
}

# Any outcome is only a result if every candidate was evaluated. Otherwise a
# newer tag may have been the right answer and the run simply could not see it,
# which must not look like "nothing to do" or like a confident pick.
assert_all_evaluated() {
  if [ "$EVALUATION_ERRORS" -gt 0 ]; then
    log_error "could not evaluate ${EVALUATION_ERRORS} candidate(s), so this run's outcome is not trustworthy; a newer tag may have been missed"
    exit 1
  fi
}

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

# The three places the tag appears must already agree. On the adopt path they are
# rewritten together, so a mismatch here means someone changed one by hand, and a
# no-op run would otherwise let that drift sit indefinitely while reporting success.
CURRENT_APP_VERSION=$(yq eval '.appVersion' "$CHART_FILE")
if [ "$CURRENT_APP_VERSION" != "$CURRENT_TAG" ]; then
  log_error "${CHART_FILE} appVersion is '${CURRENT_APP_VERSION}' but ${VALUES_FILE} image.tag is '${CURRENT_TAG}'; they must match"
  exit 1
fi

if ! grep -qF -- "\`${CURRENT_TAG}\`" "$README_FILE"; then
  log_error "${README_FILE} does not document ${CURRENT_TAG}"
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

# Oldest first, so the readiness walk below can start from the newest. This is the
# same `sort -V` ordering the candidate block below depends on; see the note there
# before changing either.
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

# Every tag newer than the pinned one, across every plugin version, oldest first.
# No cap: a cap on the newest N could hide a usable tag behind a run of unusable
# newer ones, and the set is already bounded by how far behind the chart is.
# Taking only what sorts above the pinned tag makes a downgrade impossible by
# construction. The absence of a cap is also what makes it safe to discard a
# candidate's STALL_REASON when a tag IS adopted: the walk is relative to the pin,
# so a permanently broken tag newer than the new pin is still a candidate tomorrow
# and stalls then. Reinstate a cap and that re-detection stops, turning a one-day
# deferral into permanent silence. The pinned tag is appended so there is always
# something to slice at even when the listing omits it; sort -u drops the
# duplicate.
#
# The candidate set is DEFINED by `sort -V` ordering, which puts
# `vX.Y.Z-eksbuild.N` ABOVE bare `vX.Y.Z` because -eksbuild.N is a rebuild of that
# base and so is newer. Semver says the opposite, reading -eksbuild.N as a
# pre-release. Do not substitute a semver comparator here: a bare-base pin would
# stop seeing its own rebuilds and the script would report "already up to date"
# indefinitely, on a green run, with nothing to notice.
mapfile -t CANDIDATE_TAGS < <(
  printf '%s\n' "${ALL_TAGS[@]}" "$CURRENT_TAG" \
  | sort -V -u \
  | awk -v cur="$CURRENT_TAG" 'seen { print } $0 == cur { seen = 1 }'
)

# Sets MANIFEST_BODY and MANIFEST_DIGEST on success. Returns 1 when the manifest
# could NOT be evaluated, which increments EVALUATION_ERRORS, and 2 when the
# registry answered but the image is not there. Callers treat both as "not
# usable", and must not invert that: EVALUATION_ERRORS is what separates a
# trustworthy outcome, adopting or leaving the chart alone, from a failed run.
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

# Succeeds when the tag is safe to pin: an index offering usable linux/amd64 and
# linux/arm64 manifests, all present in every sampled region, with the tag pointing
# at that same index in each of them.
tag_is_ready() {
  local tag=$1
  local index index_digest arches offered region digest want rc
  local -a digests

  rc=0
  fetch_manifest "$HOME_REGION" "imageTag=${tag}" "${MANIFEST_INDEX_TYPES[@]}" || rc=$?
  if [ "$rc" -ne 0 ]; then
    if [ "$rc" -eq 2 ]; then reject_pending "${tag}: no manifest index in ${HOME_REGION}"; fi
    return 1
  fi
  # These are overwritten by the fetches in the region loop below.
  index="$MANIFEST_BODY"
  index_digest="$MANIFEST_DIGEST"

  # Diagnostic only, so a failure here must not fail the run.
  offered=$(jq -r "$OFFERED_PLATFORMS" <<<"$index" 2>/dev/null) || offered="(unavailable)"

  if ! arches=$(jq -r "[${PLATFORM_MANIFESTS} | .platform.architecture] | unique | join(\" \")" <<<"$index"); then
    log_warning "could not read platforms from the ${tag} index"
    EVALUATION_ERRORS=$((EVALUATION_ERRORS + 1))
    return 1
  fi

  # An index that does not offer both is not going to start later, so report the
  # reason rather than letting it read as a tag that is not available yet.
  for want in amd64 arm64; do
    if ! grep -qw -- "$want" <<<"$arches"; then
      reject_permanent "${tag}: index does not serve linux/${want} (usable: ${arches:-none}; offered: ${offered:-none})"
      return 1
    fi
  done

  mapfile -t digests < <(jq -r "${PLATFORM_MANIFESTS} | .digest" <<<"$index")
  if [ "${#digests[@]}" -eq 0 ]; then
    reject_permanent "${tag}: index lists no usable linux platform manifests (offered: ${offered:-none})"
    return 1
  fi

  for region in "${READINESS_REGIONS[@]}"; do
    # The home region's index is already in hand from the fetch above.
    if [ "$region" != "$HOME_REGION" ]; then
      rc=0
      fetch_manifest "$region" "imageTag=${tag}" "${MANIFEST_INDEX_TYPES[@]}" || rc=$?
      if [ "$rc" -ne 0 ]; then
        if [ "$rc" -eq 2 ]; then reject_pending "${tag}: index is not in ${region} yet"; fi
        return 1
      fi
      # Otherwise the tag could point at an older index in this region while the
      # children of the newer one happen to be present.
      if [ "$MANIFEST_DIGEST" != "$index_digest" ]; then
        reject_pending "${tag}: points at a different index in ${region} (${MANIFEST_DIGEST})"
        return 1
      fi
    fi

    for digest in "${digests[@]}"; do
      rc=0
      fetch_manifest "$region" "imageDigest=${digest}" "${MANIFEST_TYPES[@]}" || rc=$?
      if [ "$rc" -ne 0 ]; then
        if [ "$rc" -eq 2 ]; then reject_pending "${tag}: ${digest} has not replicated to ${region} yet"; fi
        return 1
      fi
    done
  done
}

# Appending the pinned tag when slicing guarantees something to slice at, which
# also makes an absent pin look identical to a current one. The listing is not
# trusted for candidates, so do not trust it for the pin either: ask the registry.
# A pin that genuinely no longer resolves means the chart points at an image that
# may not be pullable, which needs a human whatever the walk finds.
#
# The probe's error is irrelevant if and only if a tag is adopted, because adopting
# is what makes the pin's state moot. So its errors are rolled back out of the
# evaluation count here, which stops a throttled probe declining a verified-ready
# newer tag, and PIN_PROBE_FAILED carries the fact forward to the no-adoption path,
# where the probe's result is the only thing that says whether the chart is
# currently fine.
if ! printf '%s\n' "${ALL_TAGS[@]}" | grep -qxF -- "$CURRENT_TAG"; then
  PIN_ERRORS_BEFORE=$EVALUATION_ERRORS
  PIN_RC=0
  fetch_manifest "$HOME_REGION" "imageTag=${CURRENT_TAG}" "${MANIFEST_INDEX_TYPES[@]}" || PIN_RC=$?
  EVALUATION_ERRORS=$PIN_ERRORS_BEFORE

  if [ "$PIN_RC" -eq 2 ]; then
    # Assigned directly rather than through reject_permanent, which is first-wins:
    # a missing pin must outrank any candidate's rejection whatever the order.
    FIRST_REJECTION=permanent
    STALL_REASON="${CURRENT_TAG} is no longer in ${ECR_REPOSITORY}, so the chart points at an image that may not be pullable"
    log_warning "$STALL_REASON"
  elif [ "$PIN_RC" -eq 0 ]; then
    LISTING_INCOMPLETE=true
    log_warning "${CURRENT_TAG} is missing from the listing but resolves in ${HOME_REGION}; treating the listing as incomplete"
  else
    PIN_PROBE_FAILED=true
    log_warning "could not probe ${CURRENT_TAG}, so not treating it as missing"
  fi
fi

NEW_TAG=""
for (( i=${#CANDIDATE_TAGS[@]}-1; i>=0; i-- )); do
  if tag_is_ready "${CANDIDATE_TAGS[i]}"; then
    NEW_TAG="${CANDIDATE_TAGS[i]}"
    break
  fi
done

# Every candidate is newer than the pinned tag, so one that could not be
# evaluated might have been the right answer. That is true whether or not an
# older candidate turned out to be usable, so this is checked before either
# outcome rather than only on the no-op path.
assert_all_evaluated

if [ -z "$NEW_TAG" ]; then
  # Reported before the probe check below, because a run that hits both needs the
  # permanent reason: the probe failure is transient and self-resolving, while a
  # candidate rejected permanently is the one someone has to act on.
  if [ -n "$STALL_REASON" ]; then
    log_warning "not adopting a new tag (${STALL_REASON})"
    if [ -n "${GITHUB_OUTPUT:-}" ]; then
      # STALL_REASON interpolates platform strings straight out of the manifest,
      # and this lands in a public pull request body through a heredoc-delimited
      # output, so a newline in one of them could close the heredoc early and set
      # unrelated step outputs. Stripping covers every field it interpolates.
      NOTE=$(printf '%s' "A newer tag cannot be adopted and will not resolve on its own: ${STALL_REASON}" | tr -d '\n\r')
      {
        echo "stall_note<<NOTE_EOF"
        echo "$NOTE"
        echo "NOTE_EOF"
      } >>"$GITHUB_OUTPUT"
    fi
  fi

  # Nothing was adopted, so the unfinished probe above is no longer moot: the run
  # cannot say whether the chart points at an image that still exists.
  if [ "$PIN_PROBE_FAILED" = true ]; then
    log_error "${CURRENT_TAG} is absent from the listing, could not be probed, and no newer tag was adopted, so nothing verified the image the chart points at"
    exit 1
  fi

  # Same shape: the listing demonstrably under-reported, so "nothing newer" is a
  # conclusion drawn from a candidate set known to be incomplete. Harmless once a
  # tag is adopted, since each candidate is verified individually, but it cannot
  # support a no-op.
  if [ "$LISTING_INCOMPLETE" = true ]; then
    log_error "${CURRENT_TAG} was absent from a listing that still resolves it, so the candidate set is incomplete and no-op cannot be concluded from it"
    exit 1
  fi

  if [ -z "$STALL_REASON" ]; then
    if [ "${#CANDIDATE_TAGS[@]}" -eq 0 ]; then
      echo "Chart is already up to date"
    else
      log_warning "not adopting a new tag (still replicating)"
    fi
  fi

  # The only `exit 0` in this branch, deliberately shared by every path. Adding an
  # early one above, for instance to the up-to-date case, would let a later edit
  # move a check below it and skip it silently. That is how the probe check would
  # have become a no-op.
  exit 0
fi

if [ "$LISTING_INCOMPLETE" = true ]; then
  log_warning "adopting ${NEW_TAG}, the newest usable tag in a listing already shown to under-report, so a newer one may exist"
else
  echo "Newest usable tag is ${NEW_TAG}"
fi
echo "Updating chart from ${CURRENT_TAG} to ${NEW_TAG}"

CURRENT_BASE=$(base_version "$CURRENT_TAG")
NEW_BASE=$(base_version "$NEW_TAG")

# Read from the committed version, so the result is the same whether or not
# update-efa-instance-types.sh already bumped it.
COMMITTED_VERSION=$(git show "HEAD:${CHART_FILE#"${PROJECT_ROOT}/"}" | yq eval '.version' -)
if [[ ! "$COMMITTED_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  log_error "unexpected .version in ${CHART_FILE}: '${COMMITTED_VERSION}'"
  exit 1
fi

BARE="${COMMITTED_VERSION#v}"
# 10# because the regex above admits a zero-padded component and bash would read a
# leading zero as octal, so v0.08.1 would abort on "value too great for base".
IFS='.' read -r MAJOR MINOR PATCH <<< "$BARE"
MINOR=$((10#$MINOR))
PATCH=$((10#$PATCH))
UPGRADE_NOTE=""
if [ "$NEW_BASE" != "$CURRENT_BASE" ]; then
    # A new plugin version can change behaviour, so do not advertise it as a
    # chart patch.
    NEW_VERSION="v${MAJOR}.$((MINOR + 1)).0"
    UPGRADE_NOTE="Upgrades the EFA device plugin from ${CURRENT_BASE} to ${NEW_BASE}, not just a rebuild of the same version. Please review the upstream changes between those releases."
else
    NEW_VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
fi

# Everything above validates; everything below writes.
NEW_TAG="$NEW_TAG" yq eval -i '.image.tag = strenv(NEW_TAG) | .image.tag style="double"' "$VALUES_FILE"
NEW_TAG="$NEW_TAG" yq eval -i '.appVersion = strenv(NEW_TAG) | .appVersion style="double"' "$CHART_FILE"
# The dots would be wildcards in a basic regular expression, and the guard above
# matched the tag as a fixed string, so escape them to match the same thing.
# Matches because the prologue asserted the README documents CURRENT_TAG; without
# that assertion a substitution matching nothing would pass for a doc update. The
# dots would be wildcards in a basic regular expression, and that assertion used a
# fixed string, so escape them to match the same thing.
sed -i "s|\`${CURRENT_TAG//./\\.}\`|\`${NEW_TAG}\`|g" "$README_FILE"
NEW_VERSION="$NEW_VERSION" yq eval -i '.version = strenv(NEW_VERSION)' "$CHART_FILE"
echo "Chart version ${COMMITTED_VERSION} -> ${NEW_VERSION}"

if [ -n "$UPGRADE_NOTE" ]; then
  log_warning "$UPGRADE_NOTE"
  # Surfaces in the pull request body. Absent outside GitHub Actions. The
  # delimiter form keeps this correct if the note ever gains a newline.
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
      echo "upgrade_note<<UPGRADE_NOTE_EOF"
      echo "$UPGRADE_NOTE"
      echo "UPGRADE_NOTE_EOF"
    } >>"$GITHUB_OUTPUT"
  fi
fi
