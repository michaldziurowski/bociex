#!/bin/bash
set -euo pipefail

INTERNAL="eDP-1"

enable_internal() {
  hyprctl keyword monitor "$INTERNAL, preferred, auto, 1" >/dev/null
}

disable_internal() {
  hyprctl keyword monitor "$INTERNAL, disable" >/dev/null
}

external_present() {
  hyprctl -j monitors | jq -e --arg edp1 "$INTERNAL" 'map(select((.disabled | not) and .name != $edp1)) | length > 0' >/dev/null
}

lid_state() {
  if [ -d /proc/acpi/button/lid ]; then
    state_line=$(grep -h "state" /proc/acpi/button/lid/*/state 2>/dev/null | head -n1 || true)
    if echo "$state_line" | grep -qi "open"; then
      echo open
      return
    elif echo "$state_line" | grep -qi "closed"; then
      echo closed
      return
    fi
  fi
  # fallback via upower if available
  if command -v upower >/dev/null 2>&1; then
    if dev=$(upower -e | grep -i lid 2>/dev/null | head -n1); then
      val=$(upower -i "$dev" 2>/dev/null | awk -F: '/lid-is-closed/ {gsub(/ /,"",$2); print $2}')
      if [ "$val" = "yes" ]; then
        echo closed
        return
      fi
      if [ "$val" = "no" ]; then
        echo open
        return
      fi
    fi
  fi
  echo unknown
}

apply_policy_for_lid_closed() {
  if external_present; then
    disable_internal
  else
    enable_internal
  fi
}

case "${1:-}" in
startup)
  # Small delay so Hyprland enumerates monitors after login
  sleep 0.8
  echo "Current state is: $(lid_state)"
  case "$(lid_state)" in
  closed) apply_policy_for_lid_closed ;;
  open) enable_internal ;;
  *)
    enable_internal
    ;;
  esac
  ;;
close)
  apply_policy_for_lid_closed
  ;;
open)
  enable_internal
  ;;
*)
  echo "Usage: $0 {startup|close|open}" >&2
  exit 1
  ;;
esac
