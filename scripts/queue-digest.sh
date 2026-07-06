#!/usr/bin/env bash
# Print a plain-text snapshot of the teachback review queue from the
# ledger. With --summary, print a single notification-sized line instead.
# Empty output when there is nothing to say. Fails open.
set -u
. "$(dirname "$0")/lib.sh" 2>/dev/null || exit 0

summary=""
[ "${1:-}" = "--summary" ] && summary=1

ledger="$(bw_ledger)"
[ -f "$ledger" ] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

BW_SUMMARY="$summary" python3 - "$ledger" <<'PY' 2>/dev/null
import json, os, sys, datetime
items = {}
for line in open(sys.argv[1]):
    try:
        e = json.loads(line)
    except Exception:
        continue
    if e.get("type") in ("teachback", "review") and e.get("id"):
        items[e["id"]] = e
if not items:
    sys.exit(0)
today = datetime.date.today().isoformat()
active = [e for e in items.values() if not e.get("retired")]
due = sorted((e for e in active if e.get("due", "9999") <= today),
             key=lambda e: e.get("due", ""))
upcoming = sorted((e for e in active if e.get("due", "9999") > today),
                  key=lambda e: e.get("due", ""))
retired = len(items) - len(active)

if os.environ.get("BW_SUMMARY"):
    if due:
        print(f"{len(due)} due of {len(active)} — run /bandwidth:review")
    elif upcoming:
        print(f"queue clear — next review {upcoming[0].get('due')}")
    else:
        print("queue clear")
    sys.exit(0)

print(f"Review queue — {today}")
print(f"due: {len(due)} · active: {len(active)} · retired: {retired}")
if due:
    print("")
    print("Due now:")
    for e in due[:8]:
        print(f"  [{e.get('due')}] {e.get('q', '?')} (rung {e.get('box', '?')})")
    if len(due) > 8:
        print(f"  … and {len(due) - 8} more")
if upcoming:
    e = upcoming[0]
    print("")
    print(f"Next due: {e.get('due')} — {e.get('q', '?')}")
print("")
print("Run /bandwidth:review in the project session.")
PY
exit 0
