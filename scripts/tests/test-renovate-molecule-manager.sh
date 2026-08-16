#!/usr/bin/env bash
# `renovate-ansible.json` carries a customManager that extracts the `image:`
# line from `molecule.yml`, paired with a packageRule that sets `pinDigests`.
# Extraction alone is not enough for a pin: Renovate's field-wise rewrite path
# can only *change* tokens the line already holds, and a pin has to *add* one.
# With `currentValue` unchanged (`latest` → `latest`) and no `currentDigest` to
# swap, the rewritten line comes out byte-identical, `confirmIfDepUpdated` finds
# no digest, and the whole branch is discarded with `update failure`.
# `autoReplaceStringTemplate` is the only path that can add the token.
#
# Nothing else catches that. No `renovate-config-validator` runs on this repo,
# so the manager lives in a JSON no CI parses, and a missing or malformed
# template surfaces as a failing Renovate run on a downstream repository.
#
# `replaceAt` swaps the whole regex match, so the template has to reproduce the
# match in full — `image: ` prefix and trailing newline included. The assertion
# below is a round trip rather than a string comparison: the unpinned line has
# to match, the template output has to match the same regex again, and the
# digest has to come back out of it. That second extraction is exactly what
# `confirmIfDepUpdated` does. Both regex and template are read out of the JSON
# with `jq` instead of restated — a copy would drift away from what it guards.
#
# Run: scripts/tests/test-renovate-molecule-manager.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
PRESET="$REPO/renovate-ansible.json"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -f "$PRESET" ] || fail "renovate-ansible.json not found at $PRESET"

# Select the manager by the file pattern it declares, not by its position in the
# array. An index silently points at a different manager as soon as someone
# inserts one ahead of it, and the test would then assert the wrong manager
# while still passing.
SELECT='.customManagers[]
  | select(.managerFilePatterns // []
           | index("/(^|/)extensions/molecule/[^/]+/molecule\\.yml$/"))'

# `-j` throughout: the template carries a literal `\n` as its last character,
# and the trailing newline `-r` appends is indistinguishable from it once the
# value is in a shell variable.
REGEX="$(jq -j "[$SELECT | .matchStrings[]] | .[0] // empty" "$PRESET")" ||
  fail "could not parse $PRESET"
TEMPLATE="$(jq -j "[$SELECT | .autoReplaceStringTemplate] | .[0] // empty" "$PRESET")" ||
  fail "could not parse $PRESET"

[ -n "$REGEX" ] ||
  fail "no customManager in renovate-ansible.json declares the molecule.yml file pattern"

[ -n "$TEMPLATE" ] ||
  fail "the molecule customManager has no autoReplaceStringTemplate — Renovate cannot add a digest to an unpinned image line, so every pinDigest update fails with 'Digest is not updated'"

# The match starts at `image:`, so the template has to start there too, or
# `replaceAt` drops the key and leaves a dangling value behind.
case "$TEMPLATE" in
'image: '*) ;;
*) fail "autoReplaceStringTemplate does not start with 'image: ' — replaceAt swaps the full match, so a template missing the key writes a broken line" ;;
esac

case "$TEMPLATE" in
*'{{#if newDigest}}'*) ;;
*) fail "autoReplaceStringTemplate does not guard the digest slot with {{#if newDigest}} — a non-digest update would emit a bare '@'" ;;
esac

case "$TEMPLATE" in
*'{{{newValue}}}'*) ;;
*) fail "autoReplaceStringTemplate does not interpolate {{{newValue}}} — a later tag change would be written back with the old tag" ;;
esac

DEP_NAME='geerlingguy/docker-ubuntu2404-ansible'
NEW_VALUE='latest'
NEW_DIGEST='sha256:2effe0e0b8b5d24a3e0f4b1c9a7d6e5f4c3b2a190817263544332211009988ff'

UNPINNED="      image: $DEP_NAME:$NEW_VALUE"
PINNED="      image: $DEP_NAME:$NEW_VALUE@$NEW_DIGEST"

# Renovate applies matchStrings with PCRE semantics, hence `grep -P`.
matches() { printf '%s\n' "$1" | grep -Pc "$REGEX" || true; }

[ "$(matches "$UNPINNED")" -eq 1 ] ||
  fail "the regex misses the unpinned image line — Renovate would not see the dependency at all"

[ "$(matches "$PINNED")" -eq 1 ] ||
  fail "the regex misses the pinned image line — Renovate would drop the dependency once it is pinned and never refresh the digest"

# Render the template the way Renovate would for this pin, then feed the result
# back through the same regex. `confirmIfDepUpdated` re-extracts the dependency
# from the rewritten file and compares digests; if this round trip does not
# return the digest, the real run reports `Digest is not updated`.
RENDERED="$TEMPLATE"
RENDERED="${RENDERED//\{\{\{depName\}\}\}/$DEP_NAME}"
RENDERED="${RENDERED//\{\{\{newValue\}\}\}/$NEW_VALUE}"
RENDERED="${RENDERED//\{\{#if newDigest\}\}/}"
RENDERED="${RENDERED//\{\{\/if\}\}/}"
RENDERED="${RENDERED//\{\{\{newDigest\}\}\}/$NEW_DIGEST}"

case "$RENDERED" in
*'{{'*) fail "the rendered template still holds handlebars markup: $RENDERED — the guard does not understand a construct the template uses" ;;
esac

# The template ends in a literal `\n`; strip it so the rendered line can be
# compared and matched as a single line.
RENDERED="${RENDERED%'\n'}"

[ "$RENDERED" = "image: $DEP_NAME:$NEW_VALUE@$NEW_DIGEST" ] ||
  fail "the template renders '$RENDERED', not the expected pinned image line"

[ "$(matches "$RENDERED")" -eq 1 ] ||
  fail "the template output does not match the manager's own regex — confirmIfDepUpdated would find no dependency in the rewritten file"

REEXTRACTED="$(printf '%s\n' "$RENDERED" | grep -Po '(?<=@)sha256:[a-f0-9]+' || true)"
[ "$REEXTRACTED" = "$NEW_DIGEST" ] ||
  fail "re-extracting the digest from the template output yields '$REEXTRACTED', expected '$NEW_DIGEST' — this is the comparison confirmIfDepUpdated fails on today"

echo "PASS: the molecule customManager can pin a digest — template output round-trips through its own regex"
