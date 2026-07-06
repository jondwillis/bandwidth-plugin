---
name: review
description: Run due teachback items up the spaced-review ladder — quiz, corrective feedback, reschedule. Use when the user runs /bandwidth:review, asks "what's due for review?", or accepts the SessionStart due-items nudge.
argument-hint: "[max items, default all due]"
allowed-tools: Read, Bash
---

# /bandwidth:review

Spaced retrieval over the teachback queue. Expanding intervals are the whole
mechanism — reviewing at the point of near-forgetting is what converts a
session memory into a durable one.

## 1. Find due items

The ledger is append-only; the **last** event per `id` is its current state.

```bash
. "${CLAUDE_PLUGIN_ROOT}/scripts/lib.sh"
python3 - "$(bw_ledger)" <<'PY'
import json, sys, datetime
items = {}
try:
    for line in open(sys.argv[1]):
        try: e = json.loads(line)
        except Exception: continue
        if e.get("type") in ("teachback", "review") and e.get("id"):
            items[e["id"]] = e
except FileNotFoundError:
    pass
today = datetime.date.today().isoformat()
due = [e for e in items.values() if not e.get("retired") and e.get("due","9999") <= today]
due.sort(key=lambda e: e.get("due",""))
for e in due:
    print(json.dumps({k: e.get(k) for k in ("id","q","a","box","due")}))
PY
```

If nothing is due: report the next due date and count of active items, in
one line, and stop.

If `$ARGUMENTS` gives a max count, take the oldest-due N.

## 2. Quiz

One item at a time: ask `q`, wait for the user's answer, then give
corrective feedback against the canonical `a` — name the gap plainly, fill
it briefly. Judge pass/fail on substance: did they produce the load-bearing
idea, not the exact wording?

## 3. Reschedule

Ladder: `${CLAUDE_PLUGIN_OPTION_review_intervals:-1,3,7,21}` (days per rung).

- **pass** → `box` +1. New due = today + ladder[box-1] (1-indexed). If the
  new box exceeds the ladder length, the item is **retired** — log it with
  `"retired":true` and tell the user it's graduated.
- **fail** → box = 1, due = tomorrow. Re-explain the answer now (this
  re-exposure is part of the protocol, not a consolation prize).

Log one event per reviewed item, carrying `q`/`a` forward so last-wins keeps
the full record (fail open):

```bash
bw_log_event "${CLAUDE_SESSION_ID}" "review" \
  "\"id\":\"<id>\",\"q\":\"<q>\",\"a\":\"<a>\",\"result\":\"<pass|fail>\",\"box\":<n>,\"due\":\"<YYYY-MM-DD>\""
```

(Append `,\"retired\":true` for graduations. Compute dates with
`date -v+<N>d +%Y-%m-%d`.)

## 4. Close

One-line summary: N reviewed, pass rate, next due date. No pep talk.

Then refresh the out-of-band snapshot (no-op unless configured; never
mention it when it no-ops):

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/queue-digest.sh" | \
  "${CLAUDE_PLUGIN_ROOT}/scripts/deliver.sh" \
    "bandwidth — $(basename "${CLAUDE_PROJECT_DIR:-$PWD}")" - \
    "$("${CLAUDE_PLUGIN_ROOT}/scripts/queue-digest.sh" --summary)"
```

If `CLAUDE_PLUGIN_OPTION_channels` contains `slack` and
`CLAUDE_PLUGIN_OPTION_slack_channel` is set and a Slack MCP send tool is
available, mirror the one-line summary there. Best-effort; skip silently.
