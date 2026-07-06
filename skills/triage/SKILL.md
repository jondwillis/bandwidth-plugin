---
name: triage
description: Classify a task before delegating it — delegate, spot-check, pair, or keep. Use when the user asks whether or how to hand something off ("should I just have you do X?", "is this worth delegating?"), or hands over work that is clearly judgment-heavy AND central to their craft. Also /bandwidth:triage <task>.
argument-hint: "<task description>"
allowed-tools: Read, Grep, Glob, Bash
---

# /bandwidth:triage

Decide *how* a task should be delegated before doing it. The goal, per
Bainbridge: avoid the automation that removes the easy work and leaves the
human "an arbitrary residue" of monitoring and exception-handling.
Delegation should return bandwidth, not convert production effort into
(worse) supervision effort.

Task to triage: $ARGUMENTS
(If empty, triage the thing the user most recently asked for.)

## The rubric — two axes plus one gate

**Axis 1 — Mechanical ↔ Judgment.** Is the transformation rule-like with a
checkable right answer (rename, migrate, format, scaffold, transcribe), or
does it require weighing context and trade-offs (architecture, naming the
abstraction, what to cut, what to tell a person)?

**Axis 2 — Peripheral ↔ Core craft.** Is this a capability the user needs to
keep sharp — the skill they are paid for, or are deliberately building — or
genuinely peripheral to who they're trying to be?

**The gate — verification cost.** Delegation only pays when *verifying* the
output is much cheaper than *producing* it. If supervising the result costs
as much as doing the work, delegation is negative-sum: the user gets the
fatigue of evaluation without the practice of production. Say so plainly and
recommend `keep` or `pair` regardless of the axes.

## The four tiers

| Tier | When | What you do |
|---|---|---|
| **delegate** | mechanical + peripheral + cheap to verify | Do it fully, end-to-end. Report compactly: what changed, how you verified. Don't narrate. This is the point of the plugin — *actually* outsource the tedious. |
| **spot-check** | mechanical but core-craft, or moderately costly to verify | Do it, but leave visible seams: surface the 2–3 non-obvious decision points and where a spot audit would catch a mistake. Occasionally suggest the user do one of these by hand — familiarity with the failure modes is what they'll need the day the automation misfires. |
| **pair** | judgment-heavy but peripheral | Don't hand over a finished-looking artifact. Present the decision: options, trade-offs, one recommendation. The user decides; you execute the decision. |
| **keep** | judgment-heavy + core-craft, or verification ≈ production | The user drives. You support the work without doing it: retrieve context, critique drafts, check edge cases, hold the checklist. Hendrick's test governs: *"Is this tool being used to bypass the cognitive work through which understanding is built, or to support the learner in doing that work more effectively?"* |

## What to do

1. Classify. State it in at most six lines: tier, the axis calls, the
   verification-cost call, and one sentence of reasoning. No essay.
2. Log it (fail open — if this errors, continue silently):
   ```bash
   . "${CLAUDE_PLUGIN_ROOT}/scripts/lib.sh"
   bw_log_event "${CLAUDE_SESSION_ID}" "delegation" \
     "\"area\":\"<kebab-case-area>\",\"tier\":\"<tier>\",\"task\":\"<short description, json-escaped>\""
   ```
   `area` is a stable skill-area slug (e.g. `sql-migrations`, `api-design`,
   `test-writing`, `prose-docs`) — /bandwidth:pulse aggregates streaks by it,
   so reuse existing area names from the ledger when one fits.
3. Proceed according to the tier — immediately for `delegate` and
   `spot-check`; for `pair`, present the decision first; for `keep`, ask the
   user how they want to drive.

## Judgment notes

- Most tasks arrive as bundles. Split them: "migrate 40 call sites"
  (delegate) wrapped around "choose the new interface" (pair or keep).
  Triage the parts, not the bundle.
- Don't inflate tiers to seem prudent. Over-classifying mechanical work as
  `keep` recreates the tedium the user is trying to shed; that failure mode
  is as real as over-delegating.
