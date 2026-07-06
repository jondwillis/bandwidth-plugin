# bandwidth-plugin — agent notes

> This file is the canonical, harness-agnostic agent context for this
> repo. Anything tool-specific goes in the per-tool shim file (e.g.,
> `CLAUDE.md` for Claude Code, which `@AGENTS.md`-imports this file).

## What this repo is

A **Claude Code plugin** that keeps AI delegation a bandwidth multiplier
instead of a brain drain. Sibling of
[`waggledance-plugin`](https://github.com/jondwillis/waggledance-plugin) and
[`functional-emotions`](https://github.com/jondwillis/functional-emotions).

Grounded in two sources:

- Lisanne Bainbridge, *Ironies of Automation* (1983) — automation removes
  the easy work and leaves the human an "arbitrary residue" of monitoring;
  long smooth operation degrades exactly the skill needed when it fails.
- Carl Hendrick, *AI brain fry, workslop and the ironies of automation*
  (Substack, 2026) — synthesizing "workslop" (Niederhoffer et al., HBR
  Sept 2025, BetterUp Labs × Stanford Social Media Lab: fluent AI output
  that shifts the thinking burden to the recipient), "brain fry" (Bedard
  et al./BCG, HBR March 2026: fatigue from AI *oversight*, not AI use —
  replacing routine tasks actually dropped burnout 15%), and the education
  test: *is the tool bypassing the cognitive work through which
  understanding is built, or supporting it?* Full citations in README.

Design goal in one line (via Anna): **actually outsource the tedious and
repetitive, so the human's bandwidth goes to uniquely human work.**

It is a plugin — not a library, not a CLI tool.

## Structure

| Path | Contents |
|---|---|
| `.claude-plugin/plugin.json` | Manifest + userConfig (the public surface). |
| `.claude-plugin/marketplace.json` | Marketplace metadata. |
| `hooks/hooks.json` | Hook definitions (SessionStart, PreToolUse:Bash, SessionEnd). |
| `monitors/monitors.json` | Background monitor: `review-due` (emits a line to Claude when the due count rises mid-session). |
| `scripts/*.sh` | Pure bash hook implementations; read JSON from stdin, fail open. |
| `scripts/lib.sh` | Shared helpers: config, channels, state-dir resolution, ledger append (`bw_*` prefix). |
| `scripts/due_count.py` | Single source of truth for the due-item reduce (used by session-start, session-end, monitor). |
| `scripts/queue-digest.sh` | Plain-text review-queue snapshot from the ledger. |
| `scripts/deliver.sh` | Routes (title, body) to notification / Notes.app per `channels` config. Slack is skill-level (MCP). |
| `skills/*/SKILL.md` | Slash-command skills (`/bandwidth:triage`, `:slopcheck`, `:teachback`, `:review`, `:pulse`, `:tedium`). |
| `agents/tedium-hunter.md` | Read-only scanner subagent: finds repetitive chores worth fully automating. |

## Install / run

```bash
# Marketplace install
claude plugin marketplace add /path/to/bandwidth-plugin
claude plugin install bandwidth@bandwidth

# Local dev loop
claude --plugin-dir /path/to/bandwidth-plugin
```

Pure bash hooks; `python3` used opportunistically for JSON. No build step.

## Config

Configure via `/plugin config bandwidth`, or set
`CLAUDE_PLUGIN_OPTION_<key>` env vars before launching Claude.

| Key | Default | Meaning |
|---|---|---|
| `mode` | `nudge` | `off` (hooks + monitor silent; skills still work) / `nudge` (SessionStart review reminder + one-time publish nudge) / `gate` (un-slopchecked publish → permission ask). |
| `review_intervals` | `1,3,7,21` | Day intervals for the spaced-review ladder. Pass → up a rung; fail → rung 1; past the top → retired. |
| `atrophy_threshold` | `5` | Consecutive `delegate`-tier events in one area before `/bandwidth:pulse` flags atrophy risk. |
| `channels` | `session` | Comma list: `session`, `notification` (macOS banner at actionable session end), `notes` (upsert per-project `bandwidth — <project>` note in Notes.app), `slack` (skills mirror digests via connected Slack MCP). |
| `slack_channel` | *(empty)* | Target for the `slack` channel. Empty disables. Best-effort at skill level. |
| `monitor_poll_sec` | `1800` | Poll interval for the `review-due` monitor. It only emits when the due count *rises* mid-session. |

## State

State dir resolved by `bw_state_dir()` in `scripts/lib.sh`:

1. **In a project** → `${CLAUDE_PROJECT_DIR}/.claude/.bandwidth/`
2. **Plugin data dir** → `${CLAUDE_PLUGIN_DATA}/orphan/`
3. **Last resort** → `${TMPDIR}/bandwidth-${USER}/` (ephemeral)

Project-scoped state should be gitignored — add `.claude/.bandwidth/` to
the host project's `.gitignore`.

### The ledger — `ledger.jsonl`

Single append-only JSONL file; **the last event per teachback `id` wins**.
Never rewrite lines — append a superseding event. All writes go through
`bw_log_event <session> <type> <extra-fields>`.

| `type` | Written by | Fields |
|---|---|---|
| `delegation` | triage, tedium skills | `area` (stable kebab slug), `tier` (`delegate\|spot-check\|pair\|keep`), `task` |
| `teachback` | teachback skill | `id`, `q`, `a`, `box:1`, `due` (YYYY-MM-DD) |
| `review` | review skill | `id`, `q`, `a` (carried forward), `result` (`pass\|fail`), `box`, `due`, optional `retired:true` |
| `slopcheck` | slopcheck skill | `artifact`, `verdict` (`ship\|fix\|redo`). Silences the publish gate for the session. |
| `slop_nudge` | pre-publish-gate hook | `mode`. Ensures at most one nudge per session. |

## Hooks wired

| Event | Matcher | Script | Behavior |
|---|---|---|---|
| `SessionStart` | — | `session-start.sh` | Count due teachback items (via `due_count.py`); if > 0, emit additionalContext suggesting `/bandwidth:review` at a natural pause. |
| `PreToolUse` | `Bash` | `pre-publish-gate.sh` | If the command matches publish patterns (`gh pr create`, `gh release create`, `npm/pnpm/yarn/bun/cargo publish`, `gem push`, `twine upload` — deliberately **not** plain `git push`) and this session has no `slopcheck` event: nudge (additionalContext, once per session) or, in `gate` mode, `permissionDecision: ask`. |
| `SessionEnd` | — | `session-end.sh` | Skip on `clear`/`resume`. If channels include `notification`/`notes` AND (due > 0 OR new teachback items this session): pipe `queue-digest.sh` into `deliver.sh`. |

Plus one background monitor (`monitors/monitors.json`): `review-due` runs
`monitor-review-due.sh`, which polls the due count and emits a single line
to Claude only when it rises mid-session (date rollover in a long session).
It stays silent at startup — SessionStart already announced the backlog.

## Delivery layer

`deliver.sh <title> [body|-] [summary]` fans out to channels enabled in
config: `notification` → banner showing `summary` (or body's first line —
never a truncated blob; `queue-digest.sh --summary` produces the standard
one-liner). Uses `terminal-notifier` when installed (`-group` replaces the
prior banner instead of stacking; click activates Notes.app when the notes
channel is on) and falls back to `osascript display notification`, whose
known quirk is that clicking the banner opens Script Editor — recommend
`brew install terminal-notifier`. `notes` → AppleScript upsert of a note
named `<title>` (HTML body, falls back from folder "Notes" to folder 1 of
the default account). macOS only; first Notes.app touch triggers a TCC
Automation consent prompt.
`slack` has no bash credentials — skills mirror digests via whatever Slack
MCP send tool is connected, best-effort, silent on absence. `session` means
in-chat only and is the default.

**Channels (research preview) roadmap:** Claude Code Channels lets MCP
servers push events into a live session and lets Claude reply through them
(Telegram / Discord / iMessage / custom; v2.1.80+, `channels` array in
plugin.json referencing an `mcpServers` key). The natural bandwidth use is
running `/bandwidth:review` over iMessage/Telegram away from the terminal —
ask a due question, grade the reply, reschedule. Requires shipping a channel
MCP server; not implemented, and no dead `channels` config is declared
until it is.

## Skills

| Skill | Purpose |
|---|---|
| `triage` | Classify before delegating: delegate / spot-check / pair / keep, on mechanical↔judgment × peripheral↔core axes, gated by verification cost. Logs `delegation`. |
| `slopcheck` | Outbound workslop audit: verified claims, false completeness, burden shift, filler, calibration → ship / fix / redo. Logs `slopcheck`. |
| `teachback` | 2–4 retrieval-practice questions on the session's substantive work; corrective feedback; seeds the review queue at box 1. |
| `review` | Runs due items up the spaced ladder; pass → next rung, fail → reset + re-explain, top rung → retired. |
| `pulse` | Read-only report: delegation mix by area, atrophy flags, queue health, slop coverage. Max one suggestion. |
| `tedium` | Dispatches the tedium-hunter agent; offers to build the top automation. |

## Key conventions

- **Every script fails open.** If anything breaks, exit 0 with no output.
  The plugin never blocks Claude Code.
- **The ledger is append-only.** State transitions are new events; readers
  reduce with last-event-wins per id.
- **No tests, no lint, no build.** Inner loop: install in a scratch
  project, exercise a skill, inspect `ledger.jsonl`.
- **Skills are markdown specs**, not code.
- **Helpers live in `scripts/lib.sh`** with the `bw_*` prefix.
- **Anti-nag is a design invariant.** One nudge per session from the gate;
  one SessionStart line; pulse gives at most one suggestion; teachback is
  offered at most once. A bandwidth plugin that nags is self-refuting.

## Relationship to sibling plugins

Coexists with waggledance-plugin and functional-emotions: distinct state
dirs (`.claude/.bandwidth/`), distinct prefixes (`bw_*` vs `wd_*` / `eh_*`),
distinct skill namespaces (`/bandwidth:*`).
