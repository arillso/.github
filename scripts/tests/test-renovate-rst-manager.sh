#!/usr/bin/env bash
# `renovate-base.json` carries a customManager that rewrites SHA-pinned GitHub
# Actions inside `.rst` documentation examples. Documentation is not code: the
# same file also holds forms that must survive untouched — placeholder SHAs a
# reader is meant to substitute, and deliberate `@v4`/`@main` counter-examples
# that exist precisely to be shown as wrong. A regex that loosened far enough to
# match those would have Renovate rewrite a "❌ Wrong" example into its opposite.
#
# Nothing else catches that. No `renovate-config-validator` runs on this repo,
# so the regex lives in a JSON no CI parses, and a loosening would first surface
# as a Renovate pull request against a downstream repository's documentation.
#
# The exclusion here is structural rather than a blacklist: a match needs a
# 40-hex digest *and* whitespace *and* a `# vN` comment, and none of the forms
# that must be spared satisfies all three. This asserts that property against a
# fixture holding every form, and reads the regex out of the JSON with `jq`
# instead of restating it — a copy would drift away from the artifact it guards.
#
# Run: scripts/tests/test-renovate-rst-manager.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
PRESET="$REPO/renovate-base.json"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

[ -f "$PRESET" ] || fail "renovate-base.json not found at $PRESET"

# Select the manager by the file pattern it declares, not by its position in the
# array. An index silently points at a different manager as soon as someone
# inserts one ahead of it, and the test would then assert the wrong regex while
# still passing.
REGEX="$(jq -r '
  [.customManagers[]
   | select(.managerFilePatterns // [] | index("/\\.rst$/"))
   | .matchStrings[]] | .[0] // empty
' "$PRESET")" || fail "could not parse $PRESET"

[ -n "$REGEX" ] ||
  fail "no customManager in renovate-base.json declares the /\\.rst\$/ file pattern"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/cicd.rst"

# Every form the documentation actually contains. Two are real pins and must
# match; the remaining four must not. They are written out individually below as
# well, because a bare count of 2 would also be satisfied by a regex that gained
# a placeholder and lost a real pin.
PIN_A='      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7'
PIN_B='      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0'
SKIP_PLACEHOLDER='      - uses: actions/checkout@<SHA>'
SKIP_DATE='      - uses: github/codeql-action/init@4e7cb6ba7d0e2c4e5c6b9b6d3a7f8c9d0e1f2a3b # 2026-08-09'
SKIP_MUTABLE_TAG='      - uses: actions/checkout@v4'
SKIP_MUTABLE_BRANCH='      - uses: actions/checkout@main'

cat >"$fixture" <<RST
Correct
-------

.. code-block:: yaml

$PIN_A
$PIN_B

Wrong
-----

.. code-block:: yaml

$SKIP_PLACEHOLDER
$SKIP_DATE
$SKIP_MUTABLE_TAG
$SKIP_MUTABLE_BRANCH
RST

# Renovate applies the matchString with PCRE semantics, hence `grep -P`.
matches() { printf '%s\n' "$1" | grep -Pc "$REGEX" || true; }

total="$(grep -Pc "$REGEX" "$fixture" || true)"
[ "$total" -eq 2 ] ||
  fail "expected 2 matching lines in the fixture, got $total"

while IFS='|' read -r label line; do
  [ -n "$label" ] || continue
  [ "$(matches "$line")" -eq 1 ] ||
    fail "the regex misses a real pin ($label) — Renovate would leave it to rot"
done <<EOF
checkout|$PIN_A
setup-python|$PIN_B
EOF

while IFS='|' read -r label line; do
  [ -n "$label" ] || continue
  [ "$(matches "$line")" -eq 0 ] ||
    fail "the regex matches $label — Renovate would rewrite a form meant to stay as it is"
done <<EOF
a placeholder SHA|$SKIP_PLACEHOLDER
a date-tagged pin|$SKIP_DATE
a mutable tag reference|$SKIP_MUTABLE_TAG
a branch reference|$SKIP_MUTABLE_BRANCH
EOF

echo "PASS: the .rst customManager matches both real pins and none of the 4 forms that must be spared"
