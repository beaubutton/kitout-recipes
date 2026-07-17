#!/usr/bin/env bash
# Require the password IMMEDIATELY when the screen locks / screensaver starts,
# using the supported modern API: `sysadminctl -screenLock immediate`.
# On macOS 10.13+ the old `defaults write com.apple.screensaver askForPasswordDelay`
# keys live in a sandboxed per-user container and no longer apply reliably —
# sysadminctl is the mechanism Apple actually honors.
# Idempotent: exits fast if the lock delay is already immediate.
set -euo pipefail

# sysadminctl -screenLock status writes to stderr; capture both streams.
status="$(sysadminctl -screenLock status 2>&1 || true)"

if printf '%s' "$status" | grep -Eqi 'immediate|delay is 0([^0-9]|$)'; then
  echo "Screen lock already requires the password immediately."
  exit 0
fi

echo "Setting screen lock to require the password immediately."
echo "You will be prompted for YOUR login password (sysadminctl authenticates you, not sudo)."
# `-password -` makes sysadminctl PROMPT for the password interactively rather than
# taking it on the command line (which would leak it into the process table / history).
sysadminctl -screenLock immediate -password -

echo "Done. Verify with: sysadminctl -screenLock status"
