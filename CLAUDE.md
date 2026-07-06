@AGENTS.md

## Claude Code specifics

- This repo *is* a Claude Code plugin. When iterating on a hook or skill,
  test in a separate scratch project rather than the plugin source dir, so
  in-development hooks don't fire on the meta-development session.
- No test/lint/build step. The "is it correct?" loop is: edit, install in a
  scratch project (`claude --plugin-dir .`), exercise the skill, inspect
  `.claude/.bandwidth/ledger.jsonl` and `/bandwidth:pulse`.
- Skill auto-invocation depends on the `description` frontmatter in each
  `skills/*/SKILL.md`. `triage` and `tedium` overlap near "should this be
  automated?" — sharpen descriptions rather than merging; triage classifies
  a single task, tedium scans the project.
- **The ledger schema is the contract.** The SessionStart hook, the publish
  gate, and the pulse/review skills all reduce the same JSONL with
  last-event-wins. Don't add event types or rename fields without updating
  all four readers (AGENTS.md table is the source of truth).
- The pre-publish gate intentionally excludes plain `git push` — pushing a
  WIP branch isn't publishing to a recipient. Don't "fix" that without a
  config knob.
- The first `notes` delivery triggers a macOS Automation (TCC) consent
  prompt for controlling Notes.app. `deliver.sh` fails open if denied —
  symptom is simply "no note appears". Notification delivery needs no TCC.
- The `review-due` monitor must stay silent at startup (`last=-1` guard) —
  SessionStart already announces the backlog; the monitor only reports
  *increases*. Breaking that guard double-nags every session.
