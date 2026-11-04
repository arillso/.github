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
# 3. The `Assert a review was posted` step tells a review on the head SHA, a
#    workflow-validation skip and a missing review apart. Its `run:` body runs
#    against a stubbed `gh`, because the action skips itself in exactly the pull
#    requests that change this file.
#
# Run: scripts/tests/test-claude-review.sh
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
WORKFLOW="$REPO/.github/workflows/ai-claude-review.yml"
STEP_NAME="Report permission denials"
GUARD_NAME="Assert a review was posted"
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
python3 - "$WORKFLOW" "$STEP_NAME" "$GUARD_NAME" "$tmp" <<'PY' || fail "step '$STEP_NAME' or '$GUARD_NAME' not found"
import pathlib
import sys

import yaml

wf, name, guard_name, out = sys.argv[1], sys.argv[2], sys.argv[3], pathlib.Path(sys.argv[4])
steps = yaml.safe_load(pathlib.Path(wf).read_text())["jobs"]["claude-review"]["steps"]
step = next((s for s in steps if s.get("name") == name), None)
guard = next((s for s in steps if s.get("name") == guard_name), None)
if step is None or guard is None:
    sys.exit(1)
(out / "guard_if").write_text(str(guard.get("if", "")))
(out / "guard.sh").write_text(guard["run"])
(out / "marker").write_text(guard["env"]["MARKER"])
(out / "skip_marker").write_text(guard["env"]["SKIP_MARKER"])
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

# Guard: `!cancelled()`, not `always()` — a superseded run has no review on its
# head SHA and would red the check while the newer run posts one.
guard_if="$(cat "$tmp/guard_if")"
case "$guard_if" in *'!cancelled()'*) ;; *) fail "guard if lacks !cancelled(): $guard_if" ;; esac

# Stub for the guard's `gh` calls. Fixtures come from GH_FIX_* variables; a
# missing GH_FIX_BASE_BLOB answers like the 404 of a file absent on the default
# branch. `pr comment` calls are logged so a test can assert what was posted.
mkdir "$tmp/bin"
cat >"$tmp/bin/gh" <<'STUB'
#!/usr/bin/env bash
case "$*" in
"pr comment"*) printf '%s\n' "$*" >>"$GH_FIX_LOG" ;;
*/reviews*) printf '%s' "$GH_FIX_REVIEWS" ;;
*/files*) printf '%s' "$GH_FIX_FILES" ;;
*/issues/*/comments*) printf '%s' "${GH_FIX_COMMENTS:-[]}" ;;
*/contents/*"ref=$HEAD_SHA"*) printf '%s\n' "$GH_FIX_HEAD_BLOB" ;;
*/contents/*) [ -n "${GH_FIX_BASE_BLOB:-}" ] || exit 1; printf '%s\n' "$GH_FIX_BASE_BLOB" ;;
*) echo "unexpected gh call: $*" >&2; exit 2 ;;
esac
STUB
chmod +x "$tmp/bin/gh"

MARKER="$(cat "$tmp/marker")"
SKIP_MARKER="$(cat "$tmp/skip_marker")"
BOT_ON_HEAD='[{"user":{"type":"Bot","login":"claude[bot]"},"commit_id":"head"}]'
BOT_ON_OLD='[{"user":{"type":"Bot","login":"claude[bot]"},"commit_id":"old"}]'
WF_CHANGED='[{"filename":".github/workflows/ai-claude-review.yml","status":"modified"}]'

# Runs the extracted guard body; reviews, changed files and the default-branch
# blob SHA are the inputs, the head blob SHA is always `new`. Sets `rc`.
guard() {
  : >"$tmp/comments.log"
  rc=0
  PATH="$tmp/bin:$PATH" REPO=o/r PR=1 HEAD_SHA=head DEFAULT_BRANCH=main \
    MARKER="$MARKER" SKIP_MARKER="$SKIP_MARKER" GH_FIX_LOG="$tmp/comments.log" \
    GH_FIX_REVIEWS="$1" GH_FIX_FILES="$2" GH_FIX_HEAD_BLOB=new GH_FIX_BASE_BLOB="$3" \
    bash "$tmp/guard.sh" >"$tmp/guard.out" 2>&1 || rc=$?
}

posted() {
  grep -cF -- "$1" "$tmp/comments.log" || true
}

# A bot review on the head SHA passes without a comment.
guard "$BOT_ON_HEAD" '[]' ''
[ "$rc" -eq 0 ] || fail "review on head SHA failed the guard: $(cat "$tmp/guard.out")"
[ ! -s "$tmp/comments.log" ] || fail "review on head SHA still posted a comment"

# A changed workflow file that differs from the default branch is a skip: green,
# with the skip comment. A review on an older SHA does not count.
guard "$BOT_ON_OLD" "$WF_CHANGED" old
[ "$rc" -eq 0 ] || fail "workflow-validation skip went red: $(cat "$tmp/guard.out")"
[ "$(posted "$SKIP_MARKER")" -eq 1 ] || fail "skip did not post the skip comment"
grep -q '^::notice::Review skipped' "$tmp/guard.out" || fail "skip did not emit a notice"

# A workflow file the default branch has never seen is a skip too.
guard '[]' "$WF_CHANGED" ''
[ "$rc" -eq 0 ] || fail "new workflow file did not count as a skip: $(cat "$tmp/guard.out")"

# An existing skip comment is not posted twice.
GH_FIX_COMMENTS="[{\"body\":\"$SKIP_MARKER\"}]" guard '[]' "$WF_CHANGED" old
[ "$rc" -eq 0 ] && [ ! -s "$tmp/comments.log" ] || fail "skip comment was posted twice"

# No review and no differing workflow file is a missing review: red, with the
# missing comment. Covers no workflow change, an unchanged blob and a removal.
for case in '[{"filename":"README.md","status":"modified"}]|' "$WF_CHANGED|new" \
  '[{"filename":".github/workflows/x.yml","status":"removed"}]|'; do
  guard '[]' "${case%|*}" "${case##*|}"
  [ "$rc" -eq 1 ] || fail "missing review did not fail the guard for ${case%|*}: $(cat "$tmp/guard.out")"
  [ "$(posted "$MARKER")" -eq 1 ] || fail "missing review did not post the missing comment for ${case%|*}"
  [ "$(posted "$SKIP_MARKER")" -eq 0 ] || fail "missing review was reported as a skip for ${case%|*}"
done

echo "PASS: claude-review reports permission denials, reads only arillso repositories and asserts a review"
