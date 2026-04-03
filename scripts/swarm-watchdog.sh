#!/bin/bash
# Blueprint Swarm Watchdog — auto-resumes after rate limits
#
# Runs in a tmux split pane alongside Claude Code. Monitors for rate limit
# messages, waits for the window to reset, then sends a resume prompt.
#
# Usage:
#   ./swarm-watchdog.sh                          # auto-detect Claude Code pane
#   ./swarm-watchdog.sh 0:0.0                    # specify tmux pane
#   ./swarm-watchdog.sh 0:0.0 20                 # specify pane + max retries
#   WATCHDOG_LOG=/path/to/log ./swarm-watchdog.sh  # custom log path
#
# Environment:
#   WATCHDOG_LOG        — log file path (default: /tmp/swarm-watchdog.log)
#   WATCHDOG_MARGIN     — seconds to wait after reset time (default: 60)
#   WATCHDOG_POLL       — seconds between pane checks (default: 5)
#   WATCHDOG_MAX_RETRIES — max rate limit recoveries (default: 20)

set -euo pipefail

# --- Configuration ---
CLAUDE_PANE="${1:-}"
MAX_RETRIES="${2:-${WATCHDOG_MAX_RETRIES:-20}}"
POLL_INTERVAL="${WATCHDOG_POLL:-5}"
SAFETY_MARGIN="${WATCHDOG_MARGIN:-60}"
LOG_FILE="${WATCHDOG_LOG:-/tmp/swarm-watchdog.log}"

RESUME_PROMPT='Resume the swarm. Read the state.json file in the data/ directory and continue from the next pending wave. Do not ask questions — just resume execution.'

# --- Logging ---
log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
  echo "$msg" | tee -a "$LOG_FILE"
}

# --- Find Claude Code pane ---
find_claude_pane() {
  if [[ -n "$CLAUDE_PANE" ]]; then
    echo "$CLAUDE_PANE"
    return
  fi

  # Find the pane running claude (not this watchdog)
  local pane
  pane=$(tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null \
    | grep -i 'claude' \
    | head -1 \
    | awk '{print $1}')

  if [[ -z "$pane" ]]; then
    # Fallback: assume pane 0 of current window
    pane=$(tmux display-message -p '#{session_name}:#{window_index}.0' 2>/dev/null || echo "0:0.0")
  fi
  echo "$pane"
}

# --- Capture pane content ---
capture_pane() {
  local pane="$1"
  tmux capture-pane -t "$pane" -p -S -50 2>/dev/null || echo ""
}

# --- Detect rate limit message ---
# Returns the reset time string if found, empty if not
detect_rate_limit() {
  local content="$1"

  # Match patterns like:
  #   "usage limit reached" / "rate limit" / "limit reached"
  #   "resets at 3pm" / "resets 3:00 PM" / "Resets at 2026-04-03T15:00"
  #   "Usage limit reached. Resets at 3pm"
  if echo "$content" | grep -iqE '(usage.?limit|rate.?limit|limit.?reached|token.?limit)'; then
    # Try to extract reset time
    local reset_time

    # Pattern 1: "Resets at 3pm" or "resets at 3:00 PM"
    reset_time=$(echo "$content" | grep -ioE 'resets?\s+(at\s+)?[0-9]{1,2}(:[0-9]{2})?\s*(am|pm)' | tail -1 | grep -ioE '[0-9]{1,2}(:[0-9]{2})?\s*(am|pm)')

    # Pattern 2: ISO format "resets at 2026-04-03T15:00"
    if [[ -z "$reset_time" ]]; then
      reset_time=$(echo "$content" | grep -ioE 'resets?\s+(at\s+)?[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}' | tail -1 | grep -ioE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}')
    fi

    # Pattern 3: "resets in Xh Ym" or "resets in X hours"
    if [[ -z "$reset_time" ]]; then
      local duration
      duration=$(echo "$content" | grep -ioE 'resets?\s+in\s+[0-9]+\s*(h|hour|hr)' | tail -1 | grep -ioE '[0-9]+')
      if [[ -n "$duration" ]]; then
        # Calculate absolute reset time from relative duration
        reset_time=$(date -v+"${duration}H" '+%Y-%m-%dT%H:%M' 2>/dev/null || date -d "+${duration} hours" '+%Y-%m-%dT%H:%M' 2>/dev/null)
      fi
    fi

    if [[ -n "$reset_time" ]]; then
      echo "$reset_time"
    else
      # Rate limit detected but couldn't parse reset time — use fallback
      echo "FALLBACK"
    fi
  fi
}

# --- Parse reset time to epoch seconds ---
parse_reset_epoch() {
  local reset_str="$1"

  if [[ "$reset_str" == "FALLBACK" ]]; then
    # Default: wait 5 hours from now
    echo $(( $(date +%s) + 18000 ))
    return
  fi

  # Try ISO format first
  if echo "$reset_str" | grep -qE '^[0-9]{4}-[0-9]{2}'; then
    date -jf '%Y-%m-%dT%H:%M' "$reset_str" '+%s' 2>/dev/null && return
    date -d "$reset_str" '+%s' 2>/dev/null && return
  fi

  # Parse "3pm" or "3:00 PM" style
  local hour minute ampm
  ampm=$(echo "$reset_str" | grep -ioE '(am|pm)')
  hour=$(echo "$reset_str" | grep -oE '^[0-9]{1,2}')
  minute=$(echo "$reset_str" | grep -oE ':[0-9]{2}' | tr -d ':')
  minute="${minute:-00}"

  if [[ -n "$hour" && -n "$ampm" ]]; then
    ampm=$(echo "$ampm" | tr '[:upper:]' '[:lower:]')
    if [[ "$ampm" == "pm" && "$hour" -ne 12 ]]; then
      hour=$((hour + 12))
    elif [[ "$ampm" == "am" && "$hour" -eq 12 ]]; then
      hour=0
    fi

    local target_epoch
    target_epoch=$(date -j -f '%H:%M' "$(printf '%02d:%s' "$hour" "$minute")" '+%s' 2>/dev/null)

    if [[ -z "$target_epoch" ]]; then
      # Linux fallback
      target_epoch=$(date -d "$(printf '%02d:%s' "$hour" "$minute")" '+%s' 2>/dev/null)
    fi

    # If the parsed time is in the past, it means tomorrow
    if [[ -n "$target_epoch" && "$target_epoch" -lt "$(date +%s)" ]]; then
      target_epoch=$((target_epoch + 86400))
    fi

    echo "${target_epoch:-$(( $(date +%s) + 18000 ))}"
    return
  fi

  # Couldn't parse — fallback to 5 hours
  echo $(( $(date +%s) + 18000 ))
}

# --- Send resume to Claude Code pane ---
send_resume() {
  local pane="$1"
  log "Sending resume prompt to pane $pane"
  # Clear any existing input, then send the resume prompt
  tmux send-keys -t "$pane" "" C-c 2>/dev/null || true
  sleep 1
  tmux send-keys -t "$pane" "$RESUME_PROMPT" Enter
}

# --- Main loop ---
main() {
  log "=========================================="
  log "Blueprint Swarm Watchdog starting"
  log "Max retries: $MAX_RETRIES"
  log "Poll interval: ${POLL_INTERVAL}s"
  log "Safety margin: ${SAFETY_MARGIN}s"
  log "=========================================="

  local pane
  pane=$(find_claude_pane)
  log "Monitoring pane: $pane"

  local retry_count=0
  local last_limit_time=0

  while [[ "$retry_count" -lt "$MAX_RETRIES" ]]; do
    sleep "$POLL_INTERVAL"

    local content
    content=$(capture_pane "$pane")

    if [[ -z "$content" ]]; then
      continue
    fi

    local reset_time_str
    reset_time_str=$(detect_rate_limit "$content")

    if [[ -z "$reset_time_str" ]]; then
      continue
    fi

    # Debounce: don't re-trigger within 5 minutes of last detection
    local now
    now=$(date +%s)
    if [[ $((now - last_limit_time)) -lt 300 ]]; then
      continue
    fi

    last_limit_time=$now
    retry_count=$((retry_count + 1))

    log "Rate limit detected! (recovery #$retry_count/$MAX_RETRIES)"
    log "Reset time string: $reset_time_str"

    local reset_epoch
    reset_epoch=$(parse_reset_epoch "$reset_time_str")
    local wait_seconds=$(( reset_epoch - now + SAFETY_MARGIN ))

    if [[ "$wait_seconds" -lt 60 ]]; then
      wait_seconds=60
    fi

    local wait_minutes=$(( wait_seconds / 60 ))
    local reset_human
    reset_human=$(date -r "$reset_epoch" '+%H:%M' 2>/dev/null || date -d "@$reset_epoch" '+%H:%M' 2>/dev/null || echo "unknown")

    log "Waiting ${wait_minutes}m (until $reset_human + ${SAFETY_MARGIN}s margin)"
    log "Sleeping $wait_seconds seconds..."

    sleep "$wait_seconds"

    # Verify Claude is still running in the pane
    local pane_cmd
    pane_cmd=$(tmux list-panes -t "$pane" -F '#{pane_current_command}' 2>/dev/null || echo "")
    if ! echo "$pane_cmd" | grep -qi 'claude\|node'; then
      log "WARNING: Claude Code doesn't appear to be running in pane $pane"
      log "Attempting resume anyway..."
    fi

    send_resume "$pane"
    log "Resume sent. Waiting 30s before monitoring again..."
    sleep 30

    # Update pane reference in case it changed
    pane=$(find_claude_pane)
  done

  log "=========================================="
  log "Max retries ($MAX_RETRIES) reached. Watchdog stopping."
  log "=========================================="
}

main
