#!/usr/bin/env python3
"""Print the number of due, non-retired teachback items in a ledger.

Usage: due_count.py <ledger.jsonl>
The ledger is append-only; the last event per item id wins. Prints 0 on
any error — callers fail open.
"""
import datetime
import json
import sys

items = {}
try:
    with open(sys.argv[1]) as f:
        for line in f:
            try:
                e = json.loads(line)
            except Exception:
                continue
            if e.get("type") in ("teachback", "review") and e.get("id"):
                items[e["id"]] = e
except Exception:
    print(0)
    sys.exit(0)

today = datetime.date.today().isoformat()
print(sum(1 for e in items.values()
          if not e.get("retired") and e.get("due", "9999") <= today))
