#!/usr/bin/env bash
# `ansible-test sanity --python X` rejects any X outside the CONTROLLER_PYTHON_VERSIONS
# of the ansible-core branch under test, so ci-ansible-collection.yml derives the
# interpreter from `matrix.ansible-version` instead of from the caller.
#
# That derivation runs only in consumer collections, never in this repository: a
# wrong entry cannot fail here, it turns every collection's sanity job red at the
# same time, on a runner, after the merge. This guard is the only place the table
# is checked before it ships.
#
# It does not keep a copy of the table. A copy is a second source of truth and
# drifts away from the thing it guards — silently, because the copy is what the
# test reads. Instead the `run:` body is extracted from the workflow with awk and
# *executed* for each matrix entry, so what is asserted is the behaviour that will
# run on the runner.
#
# The reference tuples below are the one thing that must be duplicated: they live
# in ansible/ansible, which this guard may not reach (CI runs it without network).
# They are dated, and a stale tuple is a lesser failure than an unchecked table —
# it can only cause a false alarm, never a false pass, because every assertion
# below narrows what the workflow may emit.
#
# Run: scripts/tests/test-controller-python-matrix.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
WORKFLOW="$REPO/.github/workflows/ci-ansible-collection.yml"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -f "$WORKFLOW" ] || fail "workflow not found: $WORKFLOW"

# CONTROLLER_PYTHON_VERSIONS per branch, read 2026-08-17 from
# ansible/ansible:<branch>/test/lib/ansible_test/_util/target/common/constants.py.
# Refresh together with the table in the workflow when a branch enters the matrix.
declare -A REFERENCE_TUPLES=(
  ["stable-2.18"]="3.11 3.12 3.13"
  ["stable-2.19"]="3.11 3.12 3.13"
  ["stable-2.20"]="3.12 3.13 3.14"
  ["devel"]="3.13 3.14 3.15"
)

# A value below the tuple maximum needs a reason on record, so "we picked the
# newest" stays the rule and each exception stays visible. devel's maximum is
# 3.15, which is unreleased: actions/setup-python has no build for it.
declare -A BELOW_MAX_REASON=(
  ["devel"]="3.15 is unreleased; setup-python has no build for it"
)

# A sentinel that is a valid version shape (the step validates it) but is never a
# plausible controller version, so a fall-through to the caller value is
# unmistakable in the output rather than looking like a legitimate result.
SENTINEL="9.99"

# The matrix default, read from the `ansible_versions` input rather than hardcoded:
# the entries this guard must cover are exactly the ones consumers get by default.
matrix_default() {
  awk '
    /^      ansible_versions:/ { in_input = 1; next }
    in_input && /^      [a-z_]+:/ { in_input = 0 }
    in_input && /^        default:/ {
      line = $0
      sub(/^        default:[[:space:]]*/, "", line)
      gsub(/^'"'"'|'"'"'$/, "", line)
      print line
      exit
    }
  ' "$WORKFLOW"
}

# The `run:` body of the "Determine Python version" step, dedented so it can be
# executed. Bounded by the next step (`- name:` at the step indent) so a later
# step is never swallowed into the body.
derivation_body() {
  awk '
    /^      - name: Determine Python version$/ { in_step = 1; next }
    in_step && /^      - name: / { exit }
    in_step && /^        run: \|/ { in_run = 1; next }
    in_run {
      if ($0 ~ /[^[:space:]]/ && $0 !~ /^          /) { exit }
      sub(/^          /, "")
      print
    }
  ' "$WORKFLOW"
}

DEFAULT_JSON="$(matrix_default)"
[ -n "$DEFAULT_JSON" ] || fail "could not read the ansible_versions default from the workflow"

BODY="$(derivation_body)"
[ -n "$BODY" ] || fail "could not extract the Determine Python version run: body"

# Guard the extraction itself: an awk change that silently returns a fragment
# would make every assertion below pass against nothing.
grep -q 'GITHUB_OUTPUT' <<<"$BODY" ||
  fail "the extracted run: body writes no GITHUB_OUTPUT — the awk extraction is broken"

ENTRIES=()
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  ENTRIES+=("$entry")
done < <(tr -d '[]"' <<<"$DEFAULT_JSON" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

[ ${#ENTRIES[@]} -gt 0 ] || fail "the ansible_versions default lists no entries: $DEFAULT_JSON"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Run the extracted body the way the runner does: values via env:, result via
# $GITHUB_OUTPUT.
derive() {
  local out="$tmp/output"
  : >"$out"
  ANSIBLE_VER="$1" PYTHON_VERSION="$SENTINEL" GITHUB_OUTPUT="$out" bash -c "$BODY" >/dev/null ||
    fail "the derivation exited non-zero for '$1'"
  sed -n 's/^version=//p' "$out"
}

for entry in "${ENTRIES[@]}"; do
  version="$(derive "$entry")"
  [ -n "$version" ] || fail "no version written for matrix entry '$entry'"

  # 1 — no default matrix entry may fall through to the caller's value. That
  #     fall-through is the defect this table replaced: it let a caller ask for a
  #     Python the branch's ansible-test rejects.
  [ "$version" != "$SENTINEL" ] ||
    fail "matrix entry '$entry' falls through to the caller's python_version; add it to the table"

  # 2 — every default matrix entry needs a reference tuple here, so a new entry
  #     cannot enter the matrix unchecked.
  tuple="${REFERENCE_TUPLES[$entry]:-}"
  [ -n "$tuple" ] ||
    fail "matrix entry '$entry' has no reference tuple in this guard; add its CONTROLLER_PYTHON_VERSIONS"

  # 3 — the derived value must be one the branch's ansible-test accepts.
  found=0
  for candidate in $tuple; do
    [ "$candidate" = "$version" ] && found=1 && break
  done
  [ "$found" -eq 1 ] ||
    fail "'$entry' derives Python $version, which is not in its CONTROLLER_PYTHON_VERSIONS ($tuple)"

  # 4 — below the tuple maximum only with a recorded reason, so the "newest
  #     supported interpreter" rule does not erode one quiet entry at a time.
  max=""
  for candidate in $tuple; do max="$candidate"; done
  if [ "$version" != "$max" ] && [ -z "${BELOW_MAX_REASON[$entry]:-}" ]; then
    fail "'$entry' derives Python $version but supports up to $max; raise it or record a reason in BELOW_MAX_REASON"
  fi

  echo "  $entry -> $version"
done

# An unknown branch must still honour the caller, otherwise adding a branch to the
# matrix would silently run on whatever the table happened to default to.
unknown="$(derive "stable-9.99")"
[ "$unknown" = "$SENTINEL" ] ||
  fail "an unknown branch derives '$unknown' instead of the caller's python_version"

echo "PASS: controller Python matches ansible-test support (${#ENTRIES[@]} matrix entries + unknown-branch fallback)"
