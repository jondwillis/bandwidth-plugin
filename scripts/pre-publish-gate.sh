#!/usr/bin/env bash
# PreToolUse[Bash]: when a command is publish-shaped (PR/release/package
# publish — deliberately NOT plain `git push`, to avoid nag fatigue) and
# nothing has been slopchecked this session, nudge (mode=nudge) or ask
# (mode=gate). Nudges at most once per session.
# Fails open — any error means no output, exit 0.
set -u
. "$(dirname "$0")/lib.sh" 2>/dev/null || exit 0

mode="$(bw_mode)"
[ "$mode" = "off" ] && exit 0
command -v python3 >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null)" || exit 0
[ -n "$input" ] || exit 0

out="$(printf '%s' "$input" | python3 -c '
import json, re, sys

mode, ledger = sys.argv[1], sys.argv[2]
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(0)

cmd = (data.get("tool_input") or {}).get("command", "")
publish = r"gh pr create|gh release create|npm publish|pnpm publish|yarn publish|bun publish|cargo publish|gem push|twine upload"
if not re.search(publish, cmd):
    sys.exit(0)

sid = data.get("session_id", "")
checked = nudged = False
try:
    with open(ledger) as f:
        for line in f:
            try:
                e = json.loads(line)
            except Exception:
                continue
            if e.get("session") != sid:
                continue
            if e.get("type") == "slopcheck":
                checked = True
            if e.get("type") == "slop_nudge":
                nudged = True
except Exception:
    pass
if checked or (nudged and mode != "gate"):
    sys.exit(0)

msg = ("bandwidth: this publishes work to another human, and nothing was "
       "slopchecked this session. Workslop shifts the thinking onto the "
       "recipient. If the artifact contains generated prose (PR description, "
       "docs, report) or unverified claims, run /bandwidth:slopcheck first.")
if mode == "gate":
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": msg}}))
else:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": msg}}))
' "$mode" "$(bw_ledger)" 2>/dev/null)" || exit 0

if [ -n "$out" ]; then
  sid="$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null)" || sid=""
  bw_log_event "${sid:-unknown}" "slop_nudge" "\"mode\":\"$mode\""
  printf '%s\n' "$out"
fi
exit 0
