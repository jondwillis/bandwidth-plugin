# bandwidth

**Keep AI delegation a bandwidth multiplier, not a brain drain.**

> "Actually outsource tedious and repetitive tasks so we can lean into our
> uniquely human skills to solve problems. To give us more bandwidth
> instead of drain us."
> — a friend, reading [Carl Hendrick on AI brain fry, workslop, and the
> ironies of automation](https://carlhendrick.substack.com/p/ai-brain-fry-workslop-and-the-ironies)

The failure mode is well documented. Bainbridge (1983): automation removes
the easy work and leaves the human an "arbitrary residue" of monitoring —
while degrading exactly the expertise needed on the day it fails.
"Workslop" (BetterUp Labs × Stanford): fluent AI output that shifts the
thinking burden onto whoever receives it — ~2 hours of rework per instance.
"Brain fry" (BCG): measurable fatigue from supervising AI output beyond
capacity; notably, when AI fully *replaced* routine tasks, burnout dropped
15% — the damage comes from oversight-heavy delegation, not delegation.
And Hendrick's education corollary: you can't supervise what you no longer
understand — *"you cannot connect the dots if you don't have any."*

This plugin puts small, mechanical checks at the four places that failure
mode enters a Claude Code session.

## What it does

| | Skill | The idea |
|---|---|---|
| **Before delegating** | `/bandwidth:triage <task>` | Classify on two axes — mechanical↔judgment, peripheral↔core-craft — gated by verification cost. Verdict: **delegate** fully, **spot-check**, **pair**, or **keep**. If supervising would cost more than doing, it says so. |
| **Before shipping** | `/bandwidth:slopcheck [path]` | Outbound workslop audit: are load-bearing claims *executed*, not re-read? What does fluent prose hide? Who ends up doing the thinking? Verdict: ship / fix / redo. |
| **After building** | `/bandwidth:teachback` | 2–4 retrieval-practice questions on what was just built — decisions, mechanisms, failure modes. Corrective feedback, then items enter a spaced-review queue (1, 3, 7, 21 days). `/bandwidth:review` runs what's due. |
| **Over time** | `/bandwidth:pulse` | Delegation mix by skill area, atrophy flags (N consecutive full delegations in one area), review-queue health, slop coverage. |
| **The inversion** | `/bandwidth:tedium` | Most people delegate the thinking and keep the tedium. This scans the repo (commit patterns, manual runbook steps, CI gaps) for chores worth automating *all the way* — script, hook, cron — and offers to build the winner. |

Three quiet hooks and a background monitor, all fail-open, all anti-nag by
design:

- **SessionStart** — one line if teachback reviews are due.
- **PreToolUse gate** — if a command publishes work to a human (`gh pr
  create`, `npm publish`, …) and nothing was slopchecked this session, one
  nudge (or, in `gate` mode, a permission ask). Plain `git push` is
  deliberately exempt.
- **SessionEnd** — if the queue is actionable, pushes a snapshot to your
  configured out-of-band channels.
- **review-due monitor** — speaks only if the due count *rises* mid-session.

## Out of the terminal

Reports don't have to die in the transcript. Set `channels` to any of:

| Channel | What you get |
|---|---|
| `session` | In-chat only (default). |
| `notification` | macOS banner when the review queue is actionable at session end (e.g. *"2 due of 5 — run /bandwidth:review"*). `brew install terminal-notifier` recommended: banners replace instead of stacking and clicking opens Notes.app; the bare-osascript fallback's click opens Script Editor (macOS quirk). |
| `notes` | A per-project **"bandwidth — \<project\>"** note in Notes.app, upserted with the live review-queue snapshot after teachback/review and at session end. Pulse reports mirror to their own note. |
| `slack` | Teachback/review/pulse digests mirrored to `slack_channel` via a connected Slack MCP (best-effort). |

Roadmap: Claude Code **Channels** (research preview) supports MCP servers
that push into a live session and let Claude reply back — the obvious next
step is doing your due reviews over iMessage/Telegram from the couch. That
needs a channel MCP server; it's designed for but not shipped.

## Install

```bash
claude plugin marketplace add jondwillis/bandwidth-plugin
claude plugin install bandwidth@bandwidth

# or, local dev
claude --plugin-dir /path/to/bandwidth-plugin
```

## Config

`/plugin config bandwidth`, or `CLAUDE_PLUGIN_OPTION_<key>` env vars:

| Key | Default | |
|---|---|---|
| `mode` | `nudge` | `off` \| `nudge` \| `gate` |
| `review_intervals` | `1,3,7,21` | spaced-ladder days |
| `atrophy_threshold` | `5` | consecutive full delegations before pulse flags an area |
| `channels` | `session` | comma list: `session,notification,notes,slack` |
| `slack_channel` | *(empty)* | target for `slack` delivery |
| `monitor_poll_sec` | `1800` | review-due monitor poll interval |

## State

One append-only JSONL ledger per project at `.claude/.bandwidth/ledger.jsonl`
(gitignore it). Delegations, teachback items, reviews, slopchecks. Readers
reduce with last-event-wins; nothing is ever rewritten.

## The design test

Every feature had to pass the same question Hendrick applies to education:
*is the tool being used to bypass the cognitive work through which
understanding is built, or to support doing that work more effectively?*
Delegation of the mechanical passes. Unexamined delegation of judgment
doesn't — and a plugin that nagged you about it would fail the test too,
so it mostly stays out of the way.

## References

- Bainbridge, L. (1983). [Ironies of Automation](https://doi.org/10.1016/0005-1098(83)90046-8). *Automatica*, 19(6), 775–779.
- Niederhoffer, K., Rosen Kellerman, G., Lee, A., Liebscher, A., Rapuano, K., & Hancock, J. T. (2025). [AI-Generated "Workslop" Is Destroying Productivity](https://hbr.org/2025/09/ai-generated-workslop-is-destroying-productivity). *Harvard Business Review*, September 22, 2025. (BetterUp Labs × Stanford Social Media Lab.)
- Bedard, J., Kropp, M., Hsu, M., Karaman, O., Hawes, J., & Kellerman, G. (2026). [When Using AI Leads to "Brain Fry"](https://www.bcg.com/news/5march2026-when-using-ai-leads-brain-fry). *Harvard Business Review*, March 2026. (BCG, n = 1,488 U.S. workers.)
- Hendrick, C. (2026). [AI brain fry, workslop and the ironies of automation](https://carlhendrick.substack.com/p/ai-brain-fry-workslop-and-the-ironies). Substack.

## License

MIT
