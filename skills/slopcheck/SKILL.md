---
name: slopcheck
description: Audit an artifact for workslop before it ships to another human — PR description, doc, report, message, README, or generated code plus its claims. Use before publishing, when the user asks "is this ready to send?", or runs /bandwidth:slopcheck [path].
argument-hint: "[path | 'PR' | description of the artifact]"
allowed-tools: Read, Grep, Glob, Bash, WebFetch
---

# /bandwidth:slopcheck

Workslop (Niederhoffer et al., HBR 2025 — BetterUp Labs × Stanford Social
Media Lab): *"AI-generated content that masquerades as good work but lacks
the substance to meaningfully advance a given task."* Its cruelty is asymmetric — the person who did the least
thinking does the least work, and the recipient inherits the error-detection
labor. This skill is the outbound filter.

Artifact: $ARGUMENTS
(If empty: the most recent shippable artifact in this session — the PR
description just drafted, the doc just written, the report just generated.)

## The one test

**Who ends up doing the thinking?** If the recipient must re-derive context,
re-verify claims, or reverse-engineer intent to act on this, it is workslop
no matter how fluent it reads.

## Checks — in order, and actually check

1. **Load-bearing claims are verified, not re-read.** "Tests pass" → run
   them. "Endpoint returns X" → call it. Numbers, API/flag names, links,
   version constraints → check each against reality. Rereading prose you
   generated is not verification; execution is.
2. **False completeness.** Fluent prose smooths over TODO-shaped holes. List
   explicitly what the artifact does *not* cover, and check whether the
   recipient would wrongly assume it does.
3. **Burden shift.** What context did the author have that the recipient
   lacks? (Why this approach, what was tried and rejected, what's known to
   be fragile.) If acting on the artifact requires that context, it must be
   *in* the artifact.
4. **Zero-information filler.** Count sentences deletable with no
   information loss ("This document outlines...", "It is important to note
   that..."). More than ~1 in 5 is a fluency costume.
5. **Calibration.** Does the confidence of the tone match the confidence of
   the substance? Flag every assertive sentence backed by an unverified
   guess.

## Verdict

Report in this shape, tersely:

- **Verdict: ship | fix | redo**
- `ship` — passes the one test; say so in one line, no cheerleading.
- `fix` — itemized list, each entry: location → problem → concrete fix.
  Offer to apply the fixes.
- `redo` — the artifact doesn't advance the task and patching won't save
  it; say what the recipient actually needs and offer to produce that
  instead.

Then log it (fail open):

```bash
. "${CLAUDE_PLUGIN_ROOT}/scripts/lib.sh"
bw_log_event "${CLAUDE_SESSION_ID}" "slopcheck" \
  "\"artifact\":\"<short artifact name, json-escaped>\",\"verdict\":\"<ship|fix|redo>\""
```

(The pre-publish gate hook looks for this event; logging it is what
silences the nudge for the rest of the session.)

## Judgment notes

- Be exactly as harsh with your own output as with anyone else's. Most of
  what you'll audit here, you wrote.
- Don't pad the report to look thorough — a slopcheck that is itself
  workslop is the worst possible outcome. If it's clean, one line.
