#!/usr/bin/env bash
# ai-claude-review.yml blocked arillso/ansible.system#286 three times on a
# finding the bot could not verify, and the runs only ever logged
# `permission_denials_count` — never which tool call was refused. Two
# properties of the workflow keep that from recurring, and both are structural,
# so a regression fails here rather than in a consumer's blocked pull request:
#
# 1. The `Report permission denials` step turns every refused tool call from the
#    action's execution file into exactly one `::warning::` line. Its `run:` body
#    is extracted from the workflow and executed against fixtures, so the test
#    exercises the shipped script rather than a copy of it.
# 2. `--allowedTools` grants read access to files in arillso repositories — and
#    only there. A broadened `repos/*/contents` pattern would let the agent that
#    holds `gh pr review --approve` read any repository the token reaches.
#
# Run: scripts/tests/test-claude-review.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
WORKFLOW="$REPO/.github/workflows/ai-claude-review.yml"
STEP_NAME="Report permission denials"
ARILLSO_READ='Bash(gh api repos/arillso/*/contents/*)'

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Pull the step's `if`, its `run` body and the action's `claude_args` out of the
# parsed YAML. A parser rather than awk: the `if` and the body are block
# scalars, and the allowedTools line sits inside another block scalar.
python3 - "$WORKFLOW" "$STEP_NAME" "$tmp" <<'PY' || fail "step '$STEP_NAME' not found"
import pathlib
import sys

import yaml

wf, name, out = sys.argv[1], sys.argv[2], pathlib.Path(sys.argv[3])
steps = yaml.safe_load(pathlib.Path(wf).read_text())["jobs"]["claude-review"]["steps"]
step = next((s for s in steps if s.get("name") == name), None)
if step is None:
    sys.exit(1)
action = next(s for s in steps if str(s.get("uses", "")).startswith("anthropics/claude-code-action@"))
(out / "if").write_text(str(step.get("if", "")))
(out / "run.sh").write_text(step["run"])
(out / "claude_args").write_text(action["with"]["claude_args"])
PY

step_if="$(cat "$tmp/if")"
case "$step_if" in *'always()'*) ;; *) fail "step if lacks always(): $step_if" ;; esac
case "$step_if" in
*"steps.review.outputs.execution_file != ''"*) ;;
*) fail "step if does not guard on steps.review.outputs.execution_file: $step_if" ;;
esac

# Runs the extracted body against one fixture and prints its stdout.
report() {
  printf '%s' "$1" >"$tmp/exec.json"
  EXEC_FILE="$tmp/exec.json" bash "$tmp/run.sh"
}

count_warnings() {
  grep -c '^::warning::permission denied: ' || true
}

# Two denials → two warnings.
out="$(report '[{"type":"system"},{"type":"result","permission_denials":[
  {"tool_name":"Bash","tool_use_id":"a","tool_input":{"command":"gh api repos/arillso/.github/contents/x"}},
  {"tool_name":"WebFetch","tool_use_id":"b","tool_input":{"url":"https://example.com"}}]}]')"
[ "$(printf '%s\n' "$out" | count_warnings)" -eq 2 ] || fail "two denials did not yield two warnings: $out"

# No denials, an empty list or a missing field → silence and exit 0.
for fixture in '[{"type":"result","permission_denials":[]}]' '[{"type":"result"}]' '[]'; do
  out="$(report "$fixture")" || fail "step exited non-zero on $fixture"
  [ -z "$out" ] || fail "no denials still printed output for $fixture: $out"
done

# A newline plus a workflow command in the input must not open a second line —
# that would let tool input inject `::error::` or any other runner command.
out="$(report '[{"type":"result","permission_denials":[
  {"tool_name":"Bash","tool_use_id":"c","tool_input":{"command":"echo hi\n::error::injected"}}]}]')"
[ "$(printf '%s\n' "$out" | wc -l)" -eq 1 ] || fail "multi-line tool_input produced more than one line: $out"
[ "$(printf '%s\n' "$out" | count_warnings)" -eq 1 ] || fail "multi-line tool_input lost its warning: $out"

# A long input is cut to 300 characters of JSON.
long="$(printf '%*s' 1000 '' | tr ' ' x)"
out="$(report "[{\"type\":\"result\",\"permission_denials\":[{\"tool_name\":\"Bash\",\"tool_use_id\":\"d\",\"tool_input\":{\"command\":\"$long\"}}]}]")"
input_part="${out#::warning::permission denied: Bash }"
[ "${#input_part}" -eq 300 ] || fail "long tool_input not cut to 300 characters (got ${#input_part})"

# A missing or unparsable execution file degrades to a warning, not a red job.
rm -f "$tmp/exec.json"
EXEC_FILE="$tmp/missing.json" bash "$tmp/run.sh" >/dev/null || fail "missing execution file failed the step"
out="$(report 'not json' 2>/dev/null)" || fail "unparsable execution file failed the step"
[ "$(printf '%s\n' "$out" | grep -c '^::warning::could not parse' || true)" -eq 1 ] ||
  fail "unparsable execution file did not warn: $out"

# Read access to arillso repositories, exactly once, and nothing wider.
args="$(cat "$tmp/claude_args")"
hits="$({ grep -oF "$ARILLSO_READ" <<<"$args" || true; } | wc -l)"
[ "$hits" -eq 1 ] || fail "--allowedTools must contain '$ARILLSO_READ' exactly once (found $hits)"
! grep -qF 'repos/*/contents' <<<"$args" || fail "--allowedTools grants repos/*/contents — read access must stay on arillso/*"

echo "PASS: claude-review reports permission denials and reads only arillso repositories"
