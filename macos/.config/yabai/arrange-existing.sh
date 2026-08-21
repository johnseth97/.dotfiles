#!/bin/bash

# ============================================================
# arrange-existing.sh
#
# Manual/reset arranger for currently open apps.
#
# Safe behavior:
# - Moves known apps to desired spaces.
# - Pins selected apps as floating/sticky/above idempotently.
# - Arranges Mail/Messages in the inbox space.
# - Restores the originally focused space/window afterward.
#
# Important:
# - Do NOT call this from yabai window_created/app_launched signals.
# - Use it manually, at login, or from a hotkey.
# ============================================================

set -u

lockfile="/tmp/yabai-arrange-existing.lock"

if [ -e "$lockfile" ]; then
  exit 0
fi

touch "$lockfile"
trap 'rm -f "$lockfile"' EXIT

# Small delay helps when run at login or shortly after apps open.
sleep 0.2

# ============================================================
# Helpers
# ============================================================

window_exists() {
  local wid="$1"

  [ -n "$wid" ] || return 1
  [ "$wid" != "null" ] || return 1

  yabai -m query --windows --window "$wid" >/dev/null 2>&1
}

space_exists() {
  local space="$1"

  [ -n "$space" ] || return 1
  [ "$space" != "null" ] || return 1

  yabai -m query --spaces --space "$space" >/dev/null 2>&1
}

move_app_to_space() {
  local app="$1"
  local space="$2"

  yabai -m query --windows \
    | jq -r --arg app "$app" '.[] | select(.app == $app) | .id' \
    | while read -r wid; do
        [ -n "$wid" ] || continue
        [ "$wid" != "null" ] || continue

        yabai -m window "$wid" --space "$space" 2>/dev/null
      done
}

pin_float_above_app() {
  local app="$1"

  yabai -m query --windows \
    | jq -r --arg app "$app" '.[] | select(.app == $app) | @base64' \
    | while read -r row; do
        [ -n "$row" ] || continue

        wid="$(echo "$row" | base64 --decode | jq -r '.id')"
        floating="$(echo "$row" | base64 --decode | jq -r '."is-floating"')"
        sticky="$(echo "$row" | base64 --decode | jq -r '."is-sticky"')"

        [ -n "$wid" ] || continue
        [ "$wid" != "null" ] || continue

        # Idempotent toggles: only toggle when the target state is not already set.
        [ "$floating" = "true" ] || yabai -m window "$wid" --toggle float 2>/dev/null
        [ "$sticky" = "true" ] || yabai -m window "$wid" --toggle sticky 2>/dev/null

        yabai -m window "$wid" --layer above 2>/dev/null
      done
}

arrange_inbox_space() {
  local messages_id
  local mail_id

  # This function temporarily focuses inbox so warp/balance operate predictably.
  yabai -m space inbox --focus 2>/dev/null || return 0

  messages_id="$(
    yabai -m query --windows --space inbox 2>/dev/null \
      | jq -r '.[] | select(.app=="Messages") | .id' \
      | head -n1
  )"

  mail_id="$(
    yabai -m query --windows --space inbox 2>/dev/null \
      | jq -r '.[] | select(.app=="Mail") | .id' \
      | head -n1
  )"

  # Stable split:
  # Focus Messages first, then Mail, then warp Mail east.
  if [ -n "$messages_id" ] && [ "$messages_id" != "null" ]; then
    yabai -m window "$messages_id" --focus 2>/dev/null
  fi

  if [ -n "$mail_id" ] && [ "$mail_id" != "null" ]; then
    yabai -m window "$mail_id" --focus 2>/dev/null
    yabai -m window "$mail_id" --warp east 2>/dev/null
  fi

  yabai -m space inbox --balance 2>/dev/null
}

restore_focus() {
  local original_space="$1"
  local original_window="$2"

  # Prefer restoring exact window if it still exists.
  if window_exists "$original_window"; then
    yabai -m window "$original_window" --focus 2>/dev/null
    return 0
  fi

  # Fall back to original space.
  if space_exists "$original_space"; then
    yabai -m space "$original_space" --focus 2>/dev/null
    return 0
  fi

  return 0
}

# ============================================================
# Capture current focus before arranging
# ============================================================

original_space="$(
  yabai -m query --spaces --space 2>/dev/null \
    | jq -r '.index // empty'
)"

original_window="$(
  yabai -m query --windows --window 2>/dev/null \
    | jq -r '.id // empty'
)"

# ============================================================
# Main app placement
# ============================================================

move_app_to_space "Ghostty" "term"
move_app_to_space "ChatGPT" "chat"
move_app_to_space "Safari" "web"
move_app_to_space "Discord" "comms"
move_app_to_space "Messages" "inbox"
move_app_to_space "Mail" "inbox"

# ============================================================
# Floating pinned apps
# ============================================================

pin_float_above_app "Calculator"
pin_float_above_app "iPhone Mirroring"
pin_float_above_app "Prism Launcher"
pin_float_above_app "Finder"

# ============================================================
# Inbox split layout
# ============================================================

arrange_inbox_space

# ============================================================
# Restore prior focus
# ============================================================

restore_focus "$original_space" "$original_window"
