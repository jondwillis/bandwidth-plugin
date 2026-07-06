#!/usr/bin/env bash
# bandwidth shared helpers. Every caller must fail open: if anything
# here breaks, emit nothing and exit 0. The plugin never blocks Claude Code.

bw_config() { # bw_config <key> <default>
  local var="CLAUDE_PLUGIN_OPTION_$1"
  local val="${!var:-}"
  printf '%s' "${val:-$2}"
}

bw_mode() { bw_config mode nudge; }

# bw_has_channel <name> — is a delivery channel enabled?
# channels config is a comma list: session,notification,notes,slack
bw_has_channel() {
  case ",$(bw_config channels session)," in
    *",$1,"*) return 0 ;;
    *) return 1 ;;
  esac
}

# State dir resolution:
#   1. In a project        -> ${CLAUDE_PROJECT_DIR}/.claude/.bandwidth/
#   2. Plugin data dir set -> ${CLAUDE_PLUGIN_DATA}/orphan/
#   3. Last resort         -> ${TMPDIR}/bandwidth-${USER}/ (ephemeral)
bw_state_dir() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    printf '%s' "${CLAUDE_PROJECT_DIR}/.claude/.bandwidth"
  elif [ -n "${CLAUDE_PLUGIN_DATA:-}" ]; then
    printf '%s' "${CLAUDE_PLUGIN_DATA}/orphan"
  else
    printf '%s' "${TMPDIR:-/tmp}/bandwidth-${USER:-unknown}"
  fi
}

bw_ledger() { printf '%s/ledger.jsonl' "$(bw_state_dir)"; }

# bw_log_event <session_id> <type> [extra-json-fields-without-braces]
# Appends one JSONL event. Caller is responsible for pre-escaped fields.
bw_log_event() {
  local dir ts
  dir="$(bw_state_dir)" || return 0
  mkdir -p "$dir" 2>/dev/null || return 0
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"ts":"%s","session":"%s","type":"%s"%s}\n' \
    "$ts" "$1" "$2" "${3:+,$3}" >> "$(bw_ledger)" 2>/dev/null || true
}
