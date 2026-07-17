#!/usr/bin/env bash
# Set the Mac's name in the three places macOS stores it:
#   ComputerName   — the friendly name (Sharing pane, AirDrop)
#   HostName       — the network/DNS hostname
#   LocalHostName  — the Bonjour/.local name
# Change NAME to a hostname-safe value (letters, digits, hyphens; no spaces).
# Idempotent.
set -euo pipefail

NAME="my-mac"

if [ "$(scutil --get ComputerName 2>/dev/null)" = "$NAME" ] &&
   [ "$(scutil --get HostName 2>/dev/null)" = "$NAME" ] &&
   [ "$(scutil --get LocalHostName 2>/dev/null)" = "$NAME" ]; then
  echo "Computer name already set to ${NAME}."
  exit 0
fi

# Prefer kitout's Keychain-backed askpass (sudo = true); fall back to a prompt.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

sudo_cmd scutil --set ComputerName "$NAME"
sudo_cmd scutil --set HostName "$NAME"
sudo_cmd scutil --set LocalHostName "$NAME"
echo "Computer name set to ${NAME}."
