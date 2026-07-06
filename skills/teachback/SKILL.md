---
name: teachback
description: Retrieval practice on what was just built or decided in this session, so the user retains the ability to supervise what they delegated. Use when the user says "quiz me", "teachback", asks to make sure they understood, or runs /bandwidth:teachback. Offer it (once, briefly) after completing substantive delegated work.
argument-hint: "[optional topic focus]"
allowed-tools: Read, Bash
---

# /bandwidth:teachback

The failure mode this prevents: delegate → never internalize → lose the
domain knowledge needed to evaluate the AI's next output. Hendrick: *"You
cannot connect the dots if you don't have any."* Retrieval practice — being
made to generate the answer, not recognize it — is the highest-leverage
known intervention for retention. This is that, applied to the session.

Focus: $ARGUMENTS (if empty, the whole session's substantive work)

## Selecting items

Pick **2–4** items from this session worth still knowing in a month. Good
items are decisions and mechanisms, not trivia:

- decisions with live alternatives — "why X over Y"
- mechanisms — "what actually happens when Z runs"
- failure modes — "what breaks first if W changes, and where would you look"
- load-bearing constraints — "why can't this just be done the obvious way"

Bad items: anything greppable in five seconds (flag names, file paths,
constants). If the session produced nothing worth retaining, say so and
stop — do not manufacture a quiz.

## Running it

1. Ask **one question at a time**, in plain text, and wait for the answer.
   Never multiple choice — recognition is not recall, and the generation
   attempt is where the learning happens.
2. After each answer, give **corrective feedback**: name what was right,
   name precisely what was missing or wrong, and fill the gap in two or
   three sentences. Do not grade on a curve and do not flatter — "mostly
   right, but you missed that the retry loop is what makes this idempotent"
   beats "great answer!".
3. After all items, log each one (fail open). Due date is tomorrow; the
   ladder starts at rung 1:
   ```bash
   . "${CLAUDE_PLUGIN_ROOT}/scripts/lib.sh"
   bw_log_event "${CLAUDE_SESSION_ID}" "teachback" \
     "\"id\":\"<stable-kebab-slug>\",\"q\":\"<question, json-escaped>\",\"a\":\"<canonical answer, 1-3 sentences, json-escaped>\",\"box\":1,\"due\":\"$(date -v+1d +%Y-%m-%d)\""
   ```
   The `id` must be unique and stable (e.g. `stream-retry-idempotency`);
   check the ledger for collisions before writing.

The SessionStart hook surfaces due items in future sessions;
`/bandwidth:review` runs them up the spaced ladder.

4. **Deliver out-of-band** (no-op unless configured; never mention it when
   it no-ops):
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/queue-digest.sh" | \
     "${CLAUDE_PLUGIN_ROOT}/scripts/deliver.sh" \
       "bandwidth — $(basename "${CLAUDE_PROJECT_DIR:-$PWD}")" - \
       "$("${CLAUDE_PLUGIN_ROOT}/scripts/queue-digest.sh" --summary)"
   ```
   If `CLAUDE_PLUGIN_OPTION_channels` contains `slack` and
   `CLAUDE_PLUGIN_OPTION_slack_channel` is set and a Slack MCP send tool is
   available in this session, also send the digest there (one message,
   plain text). If Slack isn't available, skip silently — best-effort.

## Judgment notes

- This is opt-in by nature. Offer it at most once after substantive work;
  if declined, drop it without comment. A learning tool that nags is a
  bandwidth drain wearing the costume of one.
- Questions about the user's *own* decisions ("why did you choose X?") are
  fair game and often the best items — articulating a reason is generative
  even when the decision was theirs.
