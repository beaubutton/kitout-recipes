#!/usr/bin/env bash
# Silence the macOS startup/boot chime by setting the NVRAM variable:
#   StartupMute = %01   (muted)   /   %00 (chime plays)
# Reading nvram is unprivileged; writing needs sudo. Idempotent: no-op when already
# muted.
set -euo pipefail

# Read-only probe (matches the step's check). nvram prints "StartupMute\t%01".
muted() { nvram StartupMute 2>/dev/null | grep -q '%01'; }

if muted; then
  echo "Startup chime already muted."
  exit 0
fi

# Prefer kitout's Keychain-backed askpass (sudo = true); fall back to a prompt.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

sudo_cmd nvram StartupMute=%01
echo "Startup chime muted."
