---
name: pulse
description: Bandwidth report from the delegation ledger — what's being delegated by area, skill-atrophy flags, teachback queue health, slopcheck coverage. Read-only. Use when the user runs /bandwidth:pulse or asks "what have I been delegating?" / "am I over-delegating?".
allowed-tools: Read, Bash
---

# /bandwidth:pulse

Read-only report over the ledger. The question it answers: *is the current
delegation pattern returning bandwidth, or quietly converting the user into
a fatigued monitor of work they can no longer do themselves?*

## Gather

```bash
. "${CLAUDE_PLUGIN_ROOT}/scripts/lib.sh"
cat "$(bw_ledger)" 2>/dev/null
```

Window: last 30 days (compare `ts` prefixes lexically). Threshold:
`${CLAUDE_PLUGIN_OPTION_atrophy_threshold:-5}`.

## Report — four short sections, ≤20 lines total

1. **Delegation mix.** Per `area`: counts by tier (delegate / spot-check /
   pair / keep), most recent task. Table, one row per area.
2. **Atrophy flags.** Any area whose most recent N delegation events are
   *all* tier `delegate`, where N ≥ threshold. Flag it with the reason
   stated once, plainly: long smooth automation degrades exactly the
   expertise needed when it fails (Bainbridge's third irony — the operator
   who never flies manual can't land when the autopilot quits). Suggest one
   concrete counter-move: take the next one manual, or ask for spot-check
   seams on the next delegation in that area.
3. **Teachback queue.** Active / due / retired counts; pass rate of the
   last 10 reviews. If items exist but reviews are chronically overdue
   (due date > 7 days past), say so — a queue nobody runs is dead weight.
4. **Slop coverage.** slopcheck events vs slop_nudge events. Nudges with no
   subsequent slopcheck mean unreviewed artifacts went out the door.

## Deliver

If `CLAUDE_PLUGIN_OPTION_channels` contains `notes`, mirror the finished
report (plain text, exactly as shown in-chat):

```bash
printf '%s' "<the report text>" | \
  "${CLAUDE_PLUGIN_ROOT}/scripts/deliver.sh" "bandwidth pulse — $(basename "${CLAUDE_PROJECT_DIR:-$PWD}")" -
```

If it contains `slack` with `CLAUDE_PLUGIN_OPTION_slack_channel` set and a
Slack MCP send tool available, send the report there too. Best-effort;
skip silently, and never mention delivery when it no-ops.

## Judgment notes

- At most **one** actionable suggestion at the end. A report that assigns
  homework in every section is itself a bandwidth drain.
- Empty or near-empty ledger: one line ("not enough data yet — triage and
  teachback events feed this"), no scaffolded empty report.
- Never editorialize about totals. High delegation volume in peripheral
  areas is the plugin working as intended, not a confession.
