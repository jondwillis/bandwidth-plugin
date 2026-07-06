#!/usr/bin/env bash
# Route a (title, body) to the configured out-of-band channels.
#
#   deliver.sh <title> [body | -] [summary]
#
# body from stdin when omitted or "-". The banner shows <summary> when
# given (keep it under ~100 chars), else the first line of body — never
# a truncated blob. Channels handled here: notification (macOS banner),
# notes (upsert a Notes.app note named <title>). The `slack` channel is
# handled at the skill level via MCP — bash has no credentials. `session`
# is a no-op by definition. macOS only; fails open everywhere.
set -u
. "$(dirname "$0")/lib.sh" 2>/dev/null || exit 0

title="${1:-bandwidth}"
if [ $# -ge 2 ] && [ "$2" != "-" ]; then body="$2"; else body="$(cat 2>/dev/null)"; fi
[ -n "$body" ] || exit 0
[ "$(uname)" = "Darwin" ] || exit 0

if bw_has_channel notification; then
  short="${3:-}"
  [ -n "$short" ] || short="$(printf '%s' "$body" | head -n1 | cut -c1-120)"
  if command -v terminal-notifier >/dev/null 2>&1; then
    # terminal-notifier gives the banner a real identity: -group replaces
    # the previous bandwidth banner instead of stacking, and when the notes
    # channel is also on, clicking activates Notes.app (instead of the
    # osascript default of opening Script Editor).
    set -- -title "$title" -message "$short" -group "bandwidth:$title"
    bw_has_channel notes && set -- "$@" -activate com.apple.Notes
    terminal-notifier "$@" >/dev/null 2>&1 || true
  else
    osascript \
      -e 'on run argv' \
      -e 'display notification (item 2 of argv) with title (item 1 of argv)' \
      -e 'end run' \
      "$title" "$short" >/dev/null 2>&1 || true
  fi
fi

if bw_has_channel notes; then
  command -v python3 >/dev/null 2>&1 || exit 0
  # Notes bodies are HTML; first block becomes the note name.
  html="$(printf '%s' "$body" | python3 -c '
import html, sys
title = sys.argv[1]
lines = sys.stdin.read().splitlines()
out = ["<div><h1>%s</h1>" % html.escape(title)]
for l in lines:
    out.append("<div>%s</div>" % html.escape(l) if l.strip() else "<div><br></div>")
out.append("</div>")
print("".join(out))' "$title" 2>/dev/null)" || exit 0
  [ -n "$html" ] || exit 0
  osascript - "$title" "$html" <<'AS' >/dev/null 2>&1 || true
on run argv
  set noteTitle to item 1 of argv
  set noteBody to item 2 of argv
  tell application "Notes"
    set matches to (notes whose name is noteTitle)
    if (count of matches) > 0 then
      set body of (item 1 of matches) to noteBody
    else
      try
        make new note at folder "Notes" of default account with properties {name:noteTitle, body:noteBody}
      on error
        make new note at folder 1 of default account with properties {name:noteTitle, body:noteBody}
      end try
    end if
  end tell
end run
AS
fi
exit 0
