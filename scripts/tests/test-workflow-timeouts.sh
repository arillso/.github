#!/usr/bin/env bash
# A job without `timeout-minutes` inherits the GitHub default of 360 minutes, so a
# hung step holds a runner for six hours instead of failing fast. That is not
# theoretical here: arillso/ansible.container run 32069256373 had two jobs sit at
# exactly 360 minutes without ever erroring.
#
# These are reusable workflows. A missing timeout is not spent once, it is spent
# in every consumer repository that calls them, and the six hours are billed and
# blocked there rather than here. This guard is the only place the property is
# checked before it ships.
#
# It keeps no copy of the per-job values. A copy is a second source of truth and
# drifts away from the thing it guards — silently, because the copy is what the
# test reads. Instead it parses the workflows and asserts the structural property:
# every job that owns a runner declares a bound, and that bound is plausible.
#
# `uses:` jobs are excluded because GitHub rejects `timeout-minutes` on a job that
# calls a reusable workflow; their bound lives in the called workflow, which this
# same guard covers.
#
# Run: scripts/tests/test-workflow-timeouts.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
WORKFLOW_DIR="$REPO/.github/workflows"

# The ceiling is a sanity bound, not a target: measured p95 across 4940 successful
# job runs in eight arillso repositories was under 2 minutes for every job. A value
# above this is far likelier to be a typo (60 for 6) than a real need, and a typo
# here restores exactly the failure mode the guard exists to prevent.
MAX_PLAUSIBLE=60

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -d "$WORKFLOW_DIR" ] || fail "workflow directory not found: $WORKFLOW_DIR"

# Emits one "<job> <kind> <timeout>" line per job. `kind` is runs-on or uses;
# `timeout` is the declared value or "-". Bounded by the job indent so a nested
# mapping key can never be mistaken for a job header, and `on:` trigger keys are
# skipped because only the block after `jobs:` is read.
jobs_of() {
  awk '
    /^jobs:$/ { in_jobs = 1; next }
    !in_jobs { next }
    /^[^ ]/ { in_jobs = 0; next }
    /^  [a-zA-Z0-9_-]+:[[:space:]]*$/ {
      if (job != "") print job, kind, timeout
      job = $1; sub(/:$/, "", job)
      kind = "none"; timeout = "-"
      next
    }
    /^    runs-on:/ { if (kind == "none") kind = "runs-on"; next }
    /^    uses:/    { if (kind == "none") kind = "uses"; next }
    /^    timeout-minutes:/ { timeout = $2; next }
    END { if (job != "") print job, kind, timeout }
  ' "$1"
}

checked=0
skipped=0

for workflow in "$WORKFLOW_DIR"/*.yml; do
  name="$(basename "$workflow")"

  # Guard the extraction itself: a workflow that parses to no jobs at all would
  # make every assertion below pass against nothing.
  parsed="$(jobs_of "$workflow")"
  [ -n "$parsed" ] || fail "$name: no jobs parsed — the awk extraction is broken"

  while read -r job kind timeout; do
    case "$kind" in
      uses)
        # 1 — GitHub rejects timeout-minutes on a reusable-workflow call, so a
        #     value here is not a stricter bound, it is a workflow that fails to
        #     load.
        [ "$timeout" = "-" ] ||
          fail "$name: job '$job' calls a reusable workflow and may not set timeout-minutes"
        skipped=$((skipped + 1))
        ;;
      runs-on)
        # 2 — every job that owns a runner declares a bound. Without one it
        #     inherits 360 minutes, in this repository and in every consumer.
        [ "$timeout" != "-" ] ||
          fail "$name: job '$job' has no timeout-minutes and would inherit the 360 minute default"

        # 3 — the bound must be a positive integer. GitHub silently ignores a
        #     value it cannot parse, which reads as "set" but behaves as unset.
        [[ "$timeout" =~ ^[1-9][0-9]*$ ]] ||
          fail "$name: job '$job' has a non-integer timeout-minutes: $timeout"

        # 4 — and it must stay plausible, so a typo cannot quietly restore the
        #     six-hour window the guard exists to close.
        [ "$timeout" -le "$MAX_PLAUSIBLE" ] ||
          fail "$name: job '$job' sets timeout-minutes: $timeout, above the plausible ceiling of $MAX_PLAUSIBLE"

        checked=$((checked + 1))
        ;;
      *)
        fail "$name: job '$job' declares neither runs-on nor uses"
        ;;
    esac
  done <<<"$parsed"
done

echo "PASS: $checked runner jobs bounded, $skipped reusable-workflow calls correctly unbounded"
