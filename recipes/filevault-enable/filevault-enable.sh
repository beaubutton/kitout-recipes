#!/usr/bin/env bash
# Enable FileVault (full-disk encryption of the startup volume) via
# `fdesetup enable`. This command is INTERACTIVE: it prompts for a user's
# password and then PRINTS A ONE-TIME PERSONAL RECOVERY KEY to stdout that is
# the ONLY way back in if the password is ever forgotten — you MUST capture and
# store it somewhere safe (kitout does not, and cannot, save it for you).
# Idempotent: no-ops once FileVault is already On. Needs sudo.
set -euo pipefail

# Read-only probe (no privilege needed). Matches the step's check.
fv_on() { fdesetup status | grep -q 'FileVault is On'; }

if fv_on; then
  echo "FileVault already enabled."
  exit 0
fi

# Prefer kitout's Keychain-backed askpass (sudo = true); fall back to a prompt.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

echo "Enabling FileVault — this WILL print a one-time recovery key below."
echo "SAVE IT NOW: it is the only way to unlock this disk if you forget your password."
echo "This step needs your interactive input; run it from a real terminal, not headless."

sudo_cmd fdesetup enable

echo "FileVault enable requested. A reboot begins encryption in the background."
echo "Re-run 'fdesetup status' after reboot to confirm 'FileVault is On'."
