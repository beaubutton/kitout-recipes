#!/usr/bin/env bash
# Route screenshots to ~/Screenshots, as shadowless PNGs.
# A script (not a bare `defaults` step) because it must create the target dir and
# write an ABSOLUTE path — macOS `defaults` does not expand `~`. Idempotent: a
# no-op once the directory exists and all three keys already match.
set -euo pipefail

dir="$HOME/Screenshots"

converged() {
  [ -d "$dir" ] &&
    [ "$(defaults read com.apple.screencapture location 2>/dev/null)" = "$dir" ] &&
    [ "$(defaults read com.apple.screencapture disable-shadow 2>/dev/null)" = "1" ] &&
    [ "$(defaults read com.apple.screencapture type 2>/dev/null)" = "png" ]
}

if converged; then
  echo "Screenshot settings already applied."
  exit 0
fi

mkdir -p "$dir"
defaults write com.apple.screencapture location -string "$dir"
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture type -string "png"

# `screencapture` reads these prefs fresh at each capture, so the settings already
# apply to the next screenshot. Restart SystemUIServer as a harmless nudge so the
# capture UI refreshes immediately; it relaunches instantly.
killall SystemUIServer 2>/dev/null || true
echo "Screenshots now save to $dir as shadowless PNGs."
