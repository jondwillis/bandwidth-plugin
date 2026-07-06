#!/usr/bin/env bash
# SessionEnd: push the review-queue snapshot out-of-band (Notes.app /
# macOS notification) when there is something actionable — due items, or
# new teachback items created this session. Informational only; fails open.
set -u
dir="$(cd "$(dirname "$0")" && pwd)"
. "$dir/lib.sh" 2>/dev/null || exit 0

[ "$(bw_mode)" = "off" ] && exit 0
bw_has_channel notification || bw_has_channel notes || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

input="$(cat 2>/dev/null)" || input=""
reason="$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("reason",""))' 2>/dev/null)" || reason=""
case "$reason" in clear | resume) exit 0 ;; esac
sid="$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null)" || sid=""

ledger="$(bw_ledger)"
[ -f "$ledger" ] || exit 0

due="$(python3 "$dir/due_count.py" "$ledger" 2>/dev/null)" || due=0
new="$(python3 -c '
import json, sys
n = 0
try:
    for line in open(sys.argv[1]):
        try:
            e = json.loads(line)
        except Exception:
            continue
        if e.get("type") == "teachback" and e.get("session") == sys.argv[2]:
            n += 1
except Exception:
    pass
print(n)' "$ledger" "${sid:-none}" 2>/dev/null)" || new=0

case "$due$new" in *[1-9]*) ;; *) exit 0 ;; esac

proj="$(basename "${CLAUDE_PROJECT_DIR:-$PWD}")"
"$dir/queue-digest.sh" | "$dir/deliver.sh" "bandwidth — $proj" - "$("$dir/queue-digest.sh" --summary)"
exit 0
