#!/usr/bin/env bash
# Set the macOS system appearance. Default MODE=auto (appearance follows the
# system Auto schedule, light by day / dark by night); MODE=dark forces Dark;
# MODE=light forces Light. Idempotent — mirrors the step's `check`.
#
# Why a script and not a plain `defaults` step: "Auto" is not a single key. It
# requires AppleInterfaceStyleSwitchesAutomatically = 1 AND the *absence* of
# AppleInterfaceStyle; a bare `defaults` write can't delete a key.
#
# For fixed dark/light we also nudge the live UI with osascript (System Events →
# appearance preferences → dark mode). We do NOT do that for `auto`: the only
# AppleScript primitive is the `dark mode` boolean, which selects a *fixed* Light
# or Dark and thereby clears "switch automatically" — i.e. it would undo Auto in
# the live UI. So in auto mode the `defaults` write is the whole change; open apps
# repaint to the schedule after a relaunch / next login.
set -euo pipefail

MODE="${MODE:-auto}"

is_auto() { [ "$(defaults read -g AppleInterfaceStyleSwitchesAutomatically 2>/dev/null)" = 1 ]; }
is_dark() {
  [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ] \
    && ! is_auto
}
is_light() {
  ! is_auto \
    && [ -z "$(defaults read -g AppleInterfaceStyle 2>/dev/null || true)" ]
}

case "$MODE" in
  auto)
    if is_auto; then echo "Appearance already Auto."; exit 0; fi ;;
  dark)
    if is_dark; then echo "Appearance already Dark."; exit 0; fi ;;
  light)
    if is_light; then echo "Appearance already Light."; exit 0; fi ;;
  *) echo "Unknown MODE '$MODE' (want auto|dark|light)." >&2; exit 2 ;;
esac

case "$MODE" in
  auto)
    # Auto = switches automatically, with no fixed AppleInterfaceStyle pin.
    # No osascript nudge here: `set dark mode` only picks a fixed Light/Dark and
    # would clear the "switch automatically" flag we just set. The defaults write
    # is the change; open apps repaint on relaunch / next login.
    defaults delete -g AppleInterfaceStyle 2>/dev/null || true
    defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true
    echo "Appearance set to Auto — new windows follow the day/night schedule."
    ;;
  dark)
    defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false
    defaults write -g AppleInterfaceStyle -string Dark
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true' >/dev/null 2>&1 || true
    echo "Appearance set to Dark."
    ;;
  light)
    defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool false
    defaults delete -g AppleInterfaceStyle 2>/dev/null || true
    osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to false' >/dev/null 2>&1 || true
    echo "Appearance set to Light."
    ;;
esac
