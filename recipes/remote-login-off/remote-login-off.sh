#!/usr/bin/env bash
# Ensure Remote Login (macOS's built-in SSH server, sshd) is OFF, via
# `systemsetup -setremotelogin off`. DO NOT adopt this recipe if you rely on
# SSHing INTO this Mac — it closes that door. Reading and writing this setting
# both need sudo on modern macOS, and the terminal/agent invoking `systemsetup`
# may also need Full Disk Access (System Settings → Privacy & Security → Full
# Disk Access) or the command silently fails to change anything. Idempotent.
set -euo pipefail

# Prefer kitout's Keychain-backed askpass (sudo = true); fall back to a prompt.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

# Read-only probe. `systemsetup` needs root even to READ -getremotelogin, so we
# read through `sudo -n` (non-interactive: uses the cached sudo timestamp, never
# prompts or hangs). Matches the step's check. If the privileged read can't run
# (no cached creds), the probe reports "not off" and we fall through to the
# idempotent write below — we never falsely claim "already off".
remote_login_off() { sudo -n systemsetup -getremotelogin 2>/dev/null | grep -qi 'Remote Login: Off'; }

if remote_login_off; then
  echo "Remote Login already off."
  exit 0
fi

sudo_cmd systemsetup -setremotelogin -f off

echo "Remote Login turned off — inbound SSH to this Mac is now disabled."
