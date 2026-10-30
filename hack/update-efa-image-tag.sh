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
# region before another. Checking the index and each platform manifest it names is
# enough, without also checking layers: ECR refuses to accept a manifest whose
# layers are not already in the repository, so a child manifest cannot be present in
# a region while its layers are still arriving.
#
# A change to the `vX.Y.Z` base is a plugin upgrade rather than a rebuild, so it
# bumps the chart's minor version instead of its patch.
#
# Only tags newer than the pinned one are considered, so the tag cannot move
# backwards. Nothing is written when there is nothing new. The script exits
# non-zero rather than silently doing nothing when it cannot establish an answer:
# the chart or registry is in a shape it does not recognise, the registry cannot be
# read, a candidate could not be evaluated, the pinned tag could neither be listed
# nor probed while no newer tag was adopted, or a file it rewrote did not come out
# holding the adopted tag.
#
# A condition it CAN establish and that someone has to act on, such as the pinned
# tag having been deleted or chart metadata having drifted with no adoption to
# repair it, goes to stall_note, which reddens the workflow run and, when a pull
# request is opened, names the cause in its body. It does not need a pull request to
# be noticed: the workflow's gate tests it directly, so a run that changed nothing
# still goes red.
#
# One that needs nobody now, either because nothing can be done about it or because
# it clears itself, goes to caveat_note, which is not in that gate. It is read only
# in the pull request body, so on a run that adopted nothing and opened no pull
# request it has no reader at all. That is the accepted cost of not reddening runs
# over conditions that are already resolving.

PROJECT_ROOT=$(git rev-parse --show-toplevel)
EFA_CHART_DIRECTORY="${PROJECT_ROOT}/stable/aws-efa-k8s-device-plugin"
VALUES_FILE="${EFA_CHART_DIRECTORY}/values.yaml"
CHART_FILE="${EFA_CHART_DIRECTORY}/Chart.yaml"
README_FILE="${EFA_CHART_DIRECTORY}/README.md"

# Sampled alongside the registry's own region. Each must be a region where the EKS
# registry uses the same account as the chart's own repository, because that account
# is read off .image.repository once and reused for every region. The opt-in regions
# and the other partitions use different accounts, so adding one of those here would
# fail every candidate on AccessDenied and exit non-zero every day.
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

# Set when the pinned tag is absent from the listing but the registry still resolves
# it, which proves the listing under-reported and so may be missing newer tags too.
# Adopting is unaffected, since each candidate is verified individually; it only
# means the adopted tag cannot be claimed to be the newest. Reported through
# caveat_note rather than stall_note: it is a state the script established rather
# than failed to establish, and nobody can repair a registry listing, so reddening
# a run over it would train people to ignore red runs.
LISTING_INCOMPLETE=false

# Whether anything has been rejected yet, and if so what kind. The walk runs
# newest first, so the first write describes the newest rejected candidate, unless
# the missing-pin check below pre-seeds it. Only emptiness is ever consulted; the
# two values are there to say which branch wrote it.
FIRST_REJECTION=""

# Candidates newer than the pin that were passed over only because their tag shape
# differs from the pin's. Recorded so a no-op run can say so, since the per-candidate
# lines scroll past in a run log nobody reads on a green day.
FAMILY_SKIPPED=""

# Candidates whose rejection could not be classified, because the probe that tells
# "not published yet" from "published, but never usable" did not complete. Treated as
# pending so a diagnostic failure cannot discard a verified adoption, and recorded so
# that choice is visible rather than assumed.
UNRESOLVED_TAGS=""

# Candidates turned down for a reason the registry gave, as opposed to passed over
# on shape. Counted separately so "nothing was adopted and the only thing in the way
# was a shape mismatch" can be distinguished from "something else was also wrong",
# which FIRST_REJECTION cannot express: it is first-wins and is never read for its
# value.
OTHER_REJECTIONS=0

# A rejection that will not resolve on its own, so it needs a human.
reject_permanent() {
  echo "  $1"
  OTHER_REJECTIONS=$((OTHER_REJECTIONS + 1))
  if [ -z "$FIRST_REJECTION" ]; then
    FIRST_REJECTION=permanent
    STALL_REASON="$1"
  fi
}

# A rejection that the next run may not see, so it needs only patience.
reject_pending() {
  echo "  $1"
  OTHER_REJECTIONS=$((OTHER_REJECTIONS + 1))
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

# Writes one note for the pull request body, and nothing at all when the text is
# empty or this is not running in GitHub Actions.
#
# Newlines are stripped because these notes interpolate registry and platform
# strings straight out of the manifest and land in a public pull request body
# through a heredoc-delimited output, where a newline could close the heredoc early
# and set unrelated step outputs. Callers accumulate everything they have to say
# into one string rather than calling twice for the same key: Actions keeps only the
# last value written, so a second call silently discards the first.
emit_note() {
  if [ -z "$2" ] || [ -z "${GITHUB_OUTPUT:-}" ]; then
    return 0
  fi
  local text
  text=$(printf '%s' "$2" | tr -d '\n\r')
  {
    echo "$1<<NOTE_EOF"
    echo "$text"
    echo "NOTE_EOF"
  } >>"$GITHUB_OUTPUT"
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

# The README's config table documents image.tag in one row. Located once, here,
# because the same line number and the same trailing token drive both the drift
# check below and the rewrite on the adopt path: sharing the anchor is what stops
# the two from disagreeing about which row they mean. Anchored on the row's
# left-hand text rather than on the pinned tag value, so it finds the row whatever
# the row currently says; anchoring on the value would match nothing exactly when
# the row had drifted, which is how this repo's README fell four releases behind.
# shellcheck disable=SC2016  # the backticks are markdown, not command substitution
README_ROW_TEXT='`image.tag` | EFA image tag |'
BACKTICK='`'
README_ROW_LINE=$(grep -nF -- "$README_ROW_TEXT" "$README_FILE" | head -1 | cut -d: -f1) || true
if [ -z "$README_ROW_LINE" ]; then
  log_error "${README_FILE} has no '${README_ROW_TEXT}' row to read or rewrite"
  exit 1
fi
# The Default cell of that row, defined as the backticked token that follows the
# row's left-hand text with nothing but whitespace in between. The rewrite below
# has to agree with this definition or the two describe different tokens, so the
# definition is stated once, here, and the rewrite's pattern is written to match it.
#
# The whitespace requirement is the part that matters. Every looser reading of
# "which token is the default" has a row shape it reads the wrong token on, and
# because the assertion after the writes reads through this same definition, it
# agrees with the mistake instead of catching it. Requiring whitespace does not
# make the definition right for every conceivable table; it makes the shape this
# table is assumed to have into something checked, so a row that violates it fails
# loudly rather than being half-rewritten silently.
#
# This function does not do the failing. It reports "no cell here" as an empty
# string and both callers discard its status. On an adopt run the postcondition below
# exits non-zero; on a no-op run the drift check records it, the script still exits
# zero, and the workflow's gate is what turns that into a red run.
#
# Text handling rather than a regex, so the row text needs no escaping. `#` in a
# parameter expansion strips the shortest leading match, so this reads the FIRST
# occurrence of the row text. sed matches its whole pattern leftmost, so on a line
# carrying the row text twice, where the first occurrence is not followed by
# whitespace and a backtick, sed moves on to the second while this stays on the
# first. The two then disagree, and the postcondition is what catches it: the row is
# half-rewritten, the postcondition sees the mismatch and exits non-zero, and the
# workflow's checkpoint restore is what puts the chart back.
readme_row_tag() {
  local line rest before
  line=$(sed -n "${README_ROW_LINE}p" "$README_FILE")
  rest=${line#*"$README_ROW_TEXT"}
  before=${rest%%"$BACKTICK"*}
  case $before in
    *[![:space:]]*) return 0 ;;
  esac
  rest=${rest#*"$BACKTICK"}
  printf '%s' "${rest%%"$BACKTICK"*}"
}

# Chart.yaml appVersion and the README row are meant to echo values.yaml image.tag,
# and both are rewritten on the adopt path. Drift is therefore recorded rather than
# refused: refusing would withhold a patch-currency bump over metadata that does not
# decide which image runs (templates/daemonset.yaml renders
# `.Values.image.tag | default .Chart.AppVersion`, and image.tag is always set,
# though appVersion does reach the cluster as the app.kubernetes.io/version label),
# and adopting is what repairs it. Only a no-op run, where nothing repairs it,
# treats it as needing a human. Nothing is asserted here.
CURRENT_APP_VERSION=$(yq eval '.appVersion' "$CHART_FILE")
CURRENT_README_TAG=$(readme_row_tag) || true
METADATA_DRIFT=""
if [ "$CURRENT_APP_VERSION" != "$CURRENT_TAG" ]; then
  METADATA_DRIFT="${CHART_FILE##*/} appVersion is '${CURRENT_APP_VERSION}' but image.tag is '${CURRENT_TAG}'"
fi
if [ "$CURRENT_README_TAG" != "$CURRENT_TAG" ]; then
  METADATA_DRIFT="${METADATA_DRIFT:+${METADATA_DRIFT}; }${README_FILE##*/} documents '${CURRENT_README_TAG}' but image.tag is '${CURRENT_TAG}'"
fi
if [ -n "$METADATA_DRIFT" ]; then
  log_warning "chart metadata has drifted from image.tag (${METADATA_DRIFT}); adopting a tag rewrites all three, a no-op run reports it instead"
fi

# Read from the committed version, so the result is the same whether or not
# update-efa-instance-types.sh already bumped it. Validated here with the other
# shape checks rather than on the adopt path: it feeds arithmetic, adopting cannot
# repair it, and a no-op run would otherwise never detect it.
COMMITTED_VERSION=$(git show "HEAD:${CHART_FILE#"${PROJECT_ROOT}/"}" | yq eval '.version' -)
if [[ ! "$COMMITTED_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  log_error "unexpected .version in ${CHART_FILE}: '${COMMITTED_VERSION}'"
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
  # The cross-region check below compares these digests as strings, so two empty
  # ones would compare equal and read as "the same index in both regions". ECR
  # always returns a digest, which is why this is an error rather than a fallback.
  if [ -z "$MANIFEST_DIGEST" ]; then
    log_warning "batch-get-image returned no digest in ${region} for ${image_id}"
    EVALUATION_ERRORS=$((EVALUATION_ERRORS + 1))
    return 1
  fi
}

# Succeeds when the tag is safe to pin: an index offering usable linux/amd64 and
# linux/arm64 manifests, all present in every sampled region, with the tag pointing
# at that same index in each of them.
tag_is_ready() {
  local tag=$1
  local index index_digest arches offered region digest want rc
  local -a digests

  # Checked before any registry call, because no registry answer would change it.
  # `sort -V` puts a bare `v0.5.22` above `v0.5.21-eksbuild.13`, so a bare tag
  # published before its eksbuild build would otherwise be adopted as the newest
  # usable tag and quietly move the chart off the EKS build it is pinned to.
  #
  # Skipped rather than rejected permanently. The tag itself will never become
  # adoptable, but the situation does clear on its own when the matching eksbuild
  # build is published, which is the normal publishing order. Calling it permanent
  # would redden every scheduled run until then, and a daily red run for a condition
  # that is resolving by itself is how people learn to ignore red runs. It is
  # reported through the channel that reaches the pull request body without
  # reddening, and a newer eksbuild tag is unaffected: the walk carries on to it.
  #
  # Neither reject_ helper is used, deliberately. Both seed FIRST_REJECTION, which is
  # first-wins, and a bare tag sorts above every -eksbuild tag of a lower base, so
  # seeding it here would suppress the escalation of every older candidate: a genuinely
  # broken index further down the walk would stop reddening the run and go unnoticed
  # for as long as a bare tag sat above it. Passing a tag over on shape has to look
  # like it was never a candidate.
  if [[ "$CURRENT_TAG" == *-eksbuild.* && "$tag" != *-eksbuild.* ]]; then
    echo "  ${tag}: passed over, no -eksbuild suffix while the chart is pinned to one"
    FAMILY_SKIPPED="${FAMILY_SKIPPED:+${FAMILY_SKIPPED}, }${tag}"
    return 1
  fi

  rc=0
  fetch_manifest "$HOME_REGION" "imageTag=${tag}" "${MANIFEST_INDEX_TYPES[@]}" || rc=$?
  if [ "$rc" -ne 0 ]; then
    # Asking for index media types makes "not published yet" and "published, but a
    # single-platform manifest rather than an index" the same empty answer. Only the
    # first resolves itself, so ask again without the media type restriction to tell
    # them apart. Otherwise a tag that can never be usable is reported as
    # replication lag, which stays quiet and green every day forever.
    if [ "$rc" -eq 2 ]; then
      local probe_errors_before=$EVALUATION_ERRORS probe_rc=0
      fetch_manifest "$HOME_REGION" "imageTag=${tag}" "${MANIFEST_TYPES[@]}" || probe_rc=$?
      # The answer is already known: the fetch above returned 2, which means the
      # registry replied and there is no index. This probe only chooses which label
      # to put on that, so it must not be able to fail the run. Its errors are
      # rolled back for that reason rather than to avoid double counting; the
      # candidate has not been counted at all, since rc 2 returns before any
      # increment. Letting them stand would mean a throttle on this diagnostic call
      # discarding an adoption of an older candidate that was fully verified, which
      # is the same trade the pin probe below is rolled back to avoid.
      #
      # The label, however, is then a guess, and a wrong guess is quiet: a tag that
      # will never be adoptable would read as one that is still replicating. So the
      # three outcomes are kept apart rather than folded into an else, and the guess
      # is recorded instead of being made silently.
      EVALUATION_ERRORS=$probe_errors_before
      if [ "$probe_rc" -eq 0 ]; then
        reject_permanent "${tag}: resolves in ${HOME_REGION} but is a single-platform manifest, not an index"
      elif [ "$probe_rc" -eq 2 ]; then
        # Confirmed absent under both media type sets, so it genuinely has not been
        # published yet. Pending is not a guess here, and needs no note.
        reject_pending "${tag}: no manifest index in ${HOME_REGION}"
      else
        reject_pending "${tag}: no manifest index in ${HOME_REGION}, and could not be probed to say whether one is coming"
        UNRESOLVED_TAGS="${UNRESOLVED_TAGS:+${UNRESOLVED_TAGS}, }${tag}"
      fi
    fi
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

  # Not `mapfile < <(jq ...)`, which discards jq's status. Defensive rather than
  # load-bearing: the arch check above already ran a stricter form of this filter
  # over the same index with its status checked, so a jq failure has been caught by
  # the time control arrives here, and the emptiness test below cannot fire either,
  # since reaching this line means at least two manifests were selected. Written this
  # way so the branch stays correct if the arch check above ever moves. Two other
  # `mapfile < <(...)` sites remain in this file, both reading a pipeline with no
  # status worth keeping.
  local digest_lines
  if ! digest_lines=$(jq -r "${PLATFORM_MANIFESTS} | .digest" <<<"$index"); then
    log_warning "could not read platform digests from the ${tag} index"
    EVALUATION_ERRORS=$((EVALUATION_ERRORS + 1))
    return 1
  fi
  mapfile -t digests <<<"$digest_lines"
  if [ "${#digests[@]}" -eq 0 ] || [ -z "${digests[0]}" ]; then
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

  # Explicit, not incidental. Without it the function's status is whatever the loop
  # above happens to leave, so appending any statement ending in a false test would
  # turn "ready" into "not ready" with no message and no error counted, which is the
  # exact shape of failure the rest of this file is written to avoid.
  return 0
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
# A here-string rather than a pipe into grep. `grep -q` exits at the first match
# while the writer is still going, the writer takes SIGPIPE, and pipefail turns that
# into status 141, which `if !` would read as "the pinned tag is absent". It needs
# only a few hundred tags with the pin some way back from the newest to fire, which
# is the state a long-stale chart is in, so the check would break exactly when it
# matters and claim the chart pointed at a deleted image.
if ! grep -qxF -- "$CURRENT_TAG" <<<"$(printf '%s\n' "${ALL_TAGS[@]}")"; then
  PIN_ERRORS_BEFORE=$EVALUATION_ERRORS
  PIN_RC=0
  # Both sets of media types, unlike the readiness walk. The only question here is
  # whether the pinned tag still resolves to anything at all; whether it resolves to
  # an index is what makes a tag adoptable, not what makes it present. Asking for
  # index types alone would report a pinned single-platform tag as deleted.
  fetch_manifest "$HOME_REGION" "imageTag=${CURRENT_TAG}" \
    "${MANIFEST_INDEX_TYPES[@]}" "${MANIFEST_TYPES[@]}" || PIN_RC=$?
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

# Built before the two outcomes split, because both report it: a run that adopts
# nothing says this is why, and a run that adopts an older tag says something newer
# was passed over, which is exactly what its reviewer is being asked to check.
#
# Two wordings, because the two paths ask the reader for different things. On a
# no-op run the point is that nothing was adopted and why, and that nobody need do
# anything. On an adopt run the passed-over tag can be a HIGHER base version than the
# one being adopted, so the point is that this pull request proposes an older plugin
# release than the newest tag in the registry, which is the one thing its reviewer
# cannot check without being told.
FAMILY_NOTE=""
FAMILY_NOTE_ADOPTED=""
if [ -n "$FAMILY_SKIPPED" ]; then
  FAMILY_NOTE="Passed over ${FAMILY_SKIPPED}: no -eksbuild suffix while the chart is pinned to one, so adopting would change which build the chart ships. This clears once the matching -eksbuild build is published, and needs a person only if the chart is meant to move back to bare tags."
  FAMILY_NOTE_ADOPTED="Also in the registry and NOT adopted: ${FAMILY_SKIPPED}, which has no -eksbuild suffix while the chart is pinned to one. If that is a newer plugin version than the tag proposed here, this pull request is deliberately not the newest thing available, and moving to a bare tag is a decision for a person."
fi

if [ -z "$NEW_TAG" ]; then
  # Several of the conditions below can hold at once, so each appends to one of two
  # strings and each string is written once at the end. Writing as they are found
  # would mean two writes to the same key, and Actions keeps only the last, so the
  # more urgent reason would disappear. ACTIONABLE reddens the run; UNACTIONABLE
  # reaches the pull request body without doing so, per the header's taxonomy.
  ACTIONABLE=""
  UNACTIONABLE=""

  # Leads the note, so that when the drift below is appended the rejection someone
  # has to act on is the sentence they read first. That ordering rests on nothing but
  # position: this is the first writer to run, and the append form here would quietly
  # demote it rather than object if a writer were ever added above.
  if [ -n "$STALL_REASON" ]; then
    log_warning "not adopting a new tag (${STALL_REASON})"
    # Trailing period so this still reads as a sentence when the drift below is
    # appended to it. None of the rejection reasons punctuate themselves.
    ACTIONABLE="${ACTIONABLE:+${ACTIONABLE} }A newer tag cannot be adopted and will not resolve on its own: ${STALL_REASON}."
  elif [ "${#CANDIDATE_TAGS[@]}" -eq 0 ]; then
    echo "Chart is already up to date"
  elif [ "$OTHER_REJECTIONS" -gt 0 ]; then
    log_warning "not adopting a new tag (still replicating)"
  fi
  # Reached whether or not the line above printed, because a shape mismatch and
  # replication lag can both be true and each needs saying.

  if [ -n "$FAMILY_NOTE" ]; then
    log_warning "$FAMILY_NOTE"
    UNACTIONABLE="${UNACTIONABLE:+${UNACTIONABLE} }${FAMILY_NOTE}"
  fi

  # Only on this path, for the reason the adopt path gives below: a candidate
  # rejected on registry evidence is re-evaluated against the new pin on the next
  # run. Here there is no new pin, so nothing re-evaluates it and the run would
  # otherwise be green with nothing said. Appended, since this is the third writer.
  if [ -n "$UNRESOLVED_TAGS" ]; then
    UNRESOLVED_NOTE="Could not tell whether ${UNRESOLVED_TAGS} is still replicating or is published in a form this chart can never use, because the probe that distinguishes them did not complete. Treated as still replicating, so this run stayed quiet; the next run settles it."
    log_warning "$UNRESOLVED_NOTE"
    UNACTIONABLE="${UNACTIONABLE:+${UNACTIONABLE} }${UNRESOLVED_NOTE}"
  fi

  # Nothing was adopted, so nothing repaired the drift and it now needs a human.
  # Appended rather than substituted: when a rejection and drift both hold, the
  # drift is the one with a fix, so it must not be the one that gets dropped.
  if [ -n "$METADATA_DRIFT" ]; then
    DRIFT_REPORT="Chart metadata has drifted and no adopted tag will repair it: ${METADATA_DRIFT}."
    log_warning "$DRIFT_REPORT"
    ACTIONABLE="${ACTIONABLE:+${ACTIONABLE} }${DRIFT_REPORT}"
  fi

  if [ "$LISTING_INCOMPLETE" = true ]; then
    # Appended, not assigned: more than one unactionable condition can hold, and
    # this is the second writer to reach this variable.
    LISTING_REPORT="${CURRENT_TAG} is absent from a listing that still resolves it, so no newer tag can be ruled out."
    UNACTIONABLE="${UNACTIONABLE:+${UNACTIONABLE} }${LISTING_REPORT}"
    log_warning "$LISTING_REPORT"
  fi

  emit_note stall_note "$ACTIONABLE"
  emit_note caveat_note "$UNACTIONABLE"

  # Below the notes, so the reason a reviewer needs is already recorded when this
  # exits. Nothing was adopted, so the unfinished probe is no longer moot: the run
  # cannot say whether the chart points at an image that still exists.
  if [ "$PIN_PROBE_FAILED" = true ]; then
    log_error "${CURRENT_TAG} is absent from the listing, could not be probed, and no newer tag was adopted, so nothing verified the image the chart points at"
    exit 1
  fi

  # The only `exit 0` in this branch, deliberately shared by every path. Adding an
  # early one above, for instance to the up-to-date case, would let a later edit
  # move a check below it and skip it silently. That is how the probe check would
  # have become a no-op.
  exit 0
fi

CAVEAT=""
if [ "$LISTING_INCOMPLETE" = true ]; then
  CAVEAT="Adopting ${NEW_TAG}, the newest usable tag in a listing that had already been shown to under-report, so a newer one may exist."
  log_warning "$CAVEAT"
  # Reaches the pull request body too, further down: this path is green, and a
  # warning in the run log is not something a reviewer sees. The caveat does not
  # recur once the new pin is listed.
else
  echo "Newest usable tag is ${NEW_TAG}"
fi

# Reported on this path too, not only when nothing is adopted, because the pull
# request would otherwise propose an older plugin release while a newer tag sat in
# the registry unmentioned.
#
# A candidate REJECTED on registry evidence is deliberately not reported here, even
# though it is also newer than the adopted tag and is the more actionable of the two.
# The difference is that it will be re-evaluated against the new pin on the next run
# and reported then, one day later at worst, whereas the shape pass-over would be
# reported identically on that next run and so gains nothing from waiting. Neither is
# lost; only one of them is worth putting in this pull request's body.
if [ -n "$FAMILY_NOTE_ADOPTED" ]; then
  log_warning "$FAMILY_NOTE_ADOPTED"
  CAVEAT="${CAVEAT:+${CAVEAT} }${FAMILY_NOTE_ADOPTED}"
fi
echo "Updating chart from ${CURRENT_TAG} to ${NEW_TAG}"

CURRENT_BASE=$(base_version "$CURRENT_TAG")
NEW_BASE=$(base_version "$NEW_TAG")

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
# Confined to the row located during validation, and within it to the Default cell
# as readme_row_tag defines it: the backticked token separated from the row text by
# whitespace alone, which is what the `[[:space:]]*` filler enforces. A looser
# filler reaches a token that is not the cell on some row shape or other, and since
# the assertion below shares this definition it would pass on the mistake: `.*`
# reaches past the cell to a code span in trailing prose, `[^\`]*` stops short at
# one in prose that precedes the cell. Neither is caught by agreement.
#
# Addressing the line by number rather than by a `^`-anchored pattern is what keeps
# a leading space or a pipe-prefixed row from being skipped, and replacing one token
# rather than the rest of the line leaves trailing cell punctuation intact. `#` is
# the delimiter because the row contains `|`, and `.` is the only pattern character
# to escape in the row text. A row carrying no backticked default matches nothing
# here; the assertion below turns that into a failure instead of a silent no-op.
sed -i "${README_ROW_LINE}s#\(${README_ROW_TEXT//./\\.}[[:space:]]*\)\`[^\`]*\`#\1\`${NEW_TAG}\`#" "$README_FILE"
NEW_VERSION="$NEW_VERSION" yq eval -i '.version = strenv(NEW_VERSION)' "$CHART_FILE"

# Reads back every one of the four writes above rather than trusting them. The
# README substitution is the reason: sed reports success whether or not it matched,
# so each earlier attempt to guard it was a hand-written copy of its assumptions
# that drifted from the write itself. A postcondition cannot drift, because it is
# the write's contract. It does not make the substitution correct, only unable to
# fail quietly: a pattern that matches the wrong token still satisfies this, which
# is why the definition of the Default cell is stated once, above.
WROTE_TAG=$(yq eval '.image.tag' "$VALUES_FILE")
WROTE_APP_VERSION=$(yq eval '.appVersion' "$CHART_FILE")
WROTE_CHART_VERSION=$(yq eval '.version' "$CHART_FILE")
WROTE_README_TAG=$(readme_row_tag) || true
if [ "$WROTE_TAG" != "$NEW_TAG" ] \
  || [ "$WROTE_APP_VERSION" != "$NEW_TAG" ] \
  || [ "$WROTE_README_TAG" != "$NEW_TAG" ] \
  || [ "$WROTE_CHART_VERSION" != "$NEW_VERSION" ]; then
  log_error "the chart was not fully rewritten to ${NEW_TAG}: image.tag is '${WROTE_TAG}', appVersion is '${WROTE_APP_VERSION}', ${README_FILE##*/} line ${README_ROW_LINE} documents '${WROTE_README_TAG}', chart version is '${WROTE_CHART_VERSION}' (expected ${NEW_VERSION})"
  exit 1
fi
echo "Chart version ${COMMITTED_VERSION} -> ${NEW_VERSION}"

# Below the assertion, so a note claiming a tag was adopted cannot outlive a failure
# that stops it being adopted. The workflow's rollback restores the chart files but
# cannot un-write a step output, so a note emitted before this point would still
# reach the pull request body beside the note saying the update was discarded.
emit_note caveat_note "$CAVEAT"

if [ -n "$UPGRADE_NOTE" ]; then
  log_warning "$UPGRADE_NOTE"
  # Surfaces in the pull request body. Absent outside GitHub Actions.
  emit_note upgrade_note "$UPGRADE_NOTE"
fi
