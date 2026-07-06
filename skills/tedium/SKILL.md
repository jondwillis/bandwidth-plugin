---
name: tedium
description: Hunt for repetitive mechanical work in this project worth fully automating — scripts, git hooks, CI, cron, codegen. The "actually outsource the tedious" pass. Use when the user runs /bandwidth:tedium, asks what to automate, or complains about a repetitive chore.
argument-hint: "[optional focus area]"
---

# /bandwidth:tedium

Most people invert Anna's rule: they delegate the thinking and keep the
tedium. This pass finds the tedium and proposes handing it *all the way*
off — not to a chat session, but to a script, hook, or pipeline that never
needs supervising.

Launch the `bandwidth:tedium-hunter` agent via the Agent tool on this
project, passing along any focus from: $ARGUMENTS

If that agent type isn't resolvable in this session, do the scan inline
following `${CLAUDE_PLUGIN_ROOT}/agents/tedium-hunter.md`.

When the results come back:

1. Present the ranked candidates as-is (chore → evidence → proposed
   automation → payoff).
2. For the top candidate, offer to build the automation now. Building it is
   a `delegate`-tier task by construction — mechanical, peripheral, cheap to
   verify — so if the user accepts, just do it.
3. Log one delegation event per automation actually built (fail open):
   ```bash
   . "${CLAUDE_PLUGIN_ROOT}/scripts/lib.sh"
   bw_log_event "${CLAUDE_SESSION_ID}" "delegation" \
     "\"area\":\"tedium-automation\",\"tier\":\"delegate\",\"task\":\"<what was automated, json-escaped>\""
   ```
