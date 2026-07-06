#!/usr/bin/env bash
# Background monitor (monitors/monitors.json): watch for teachback items
# coming due mid-session — e.g. the date rolls over during a long session.
# Every stdout line reaches Claude as a notification, so this emits ONLY
# when the due count rises above what it was at session start (SessionStart
# already announced the initial backlog). Anti-nag is the invariant.
set -u
dir="$(cd "$(dirname "$0")" && pwd)"
. "$dir/lib.sh" 2>/dev/null || exit 0

[ "$(bw_mode)" = "off" ] && exit 0
command -v python3 >/dev/null 2>&1 || exit 0

poll="${CLAUDE_PLUGIN_OPTION_monitor_poll_sec:-1800}"
case "$poll" in '' | *[!0-9]*) poll=1800 ;; esac

# Background the sleep and trap TERM/INT so the monitor dies promptly when
# the session ends instead of finishing a 30-minute nap as an orphan.
spid=""
trap '[ -n "$spid" ] && kill "$spid" 2>/dev/null; exit 0' TERM INT

last=-1
while true; do
  due="$(python3 "$dir/due_count.py" "$(bw_ledger)" 2>/dev/null)" || due=0
  case "$due" in '' | *[!0-9]*) due=0 ;; esac
  if [ "$last" -ge 0 ] && [ "$due" -gt "$last" ]; then
    echo "bandwidth: review items due rose to $due — offer /bandwidth:review at the next natural pause (never mid-task)."
  fi
  last="$due"
  sleep "$poll" &
  spid=$!
  wait "$spid" || exit 0
done
