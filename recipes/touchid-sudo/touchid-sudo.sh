#!/usr/bin/env bash
# Enable Touch ID (and a paired Apple Watch, if you use one) for `sudo` by adding
# pam_tid.so to /etc/pam.d/sudo_local. On macOS 14 (Sonoma)+ the `sudo` PAM stack
# sources sudo_local, so this SURVIVES OS updates — unlike editing /etc/pam.d/sudo
# directly, which macOS overwrites on upgrade. Idempotent.
set -euo pipefail

target='/etc/pam.d/sudo_local'
line='auth       sufficient     pam_tid.so'

if [ -f "$target" ] && grep -q '^[^#]*pam_tid\.so' "$target"; then
  echo "Touch ID for sudo already enabled."
  exit 0
fi

# Prefer kitout's Keychain-backed askpass (sudo = true) so unattended `apply -y`
# works; fall back to an interactive prompt when run standalone.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

printf '%s\n' "$line" | sudo_cmd tee -a "$target" >/dev/null
echo "Touch ID for sudo enabled — open a new terminal and try 'sudo -v'."
