#!/usr/bin/env bash
# SessionStart: surface due teachback reviews as additionalContext.
# Fails open — any error means no output, exit 0.
set -u
dir="$(cd "$(dirname "$0")" && pwd)"
. "$dir/lib.sh" 2>/dev/null || exit 0

[ "$(bw_mode)" = "off" ] && exit 0
ledger="$(bw_ledger)"
[ -f "$ledger" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

due="$(python3 "$dir/due_count.py" "$ledger" 2>/dev/null)"

case "$due" in '' | 0 | *[!0-9]*) exit 0 ;; esac

python3 - "$due" <<'PY' 2>/dev/null || exit 0
import json, sys
n = sys.argv[1]
msg = (f"bandwidth: {n} teachback review item(s) due. At a natural pause — not "
       "mid-task — offer /bandwidth:review. Retrieval practice is what keeps the "
       "user able to supervise the work they have been delegating. Do not interrupt "
       "active work for this.")
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "SessionStart", "additionalContext": msg}}))
PY
exit 0
