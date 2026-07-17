#!/usr/bin/env bash
# Turn on automatic installation of Apple SECURITY updates (system data files
# and Security Response / XProtect / MRT updates), via `softwareupdate
# --schedule on` plus the four keys in the com.apple.SoftwareUpdate domain that
# actually gate each category. This does NOT enable automatic installation of
# major macOS version upgrades — that's a separate key (AutomaticallyInstallMacOSUpdates)
# this script never touches. Needs sudo to write the system domain (reading is
# unprivileged). Idempotent.
set -euo pipefail

DOMAIN='/Library/Preferences/com.apple.SoftwareUpdate'

# Read-only probes (no privilege needed). Match the step's check.
key_true() { defaults read "$DOMAIN" "$1" 2>/dev/null | grep -q '^1$'; }

converged() {
  key_true AutomaticCheckEnabled &&
  key_true AutomaticDownload &&
  key_true ConfigDataInstall &&
  key_true CriticalUpdateInstall
}

if converged; then
  echo "Automatic security updates already enabled."
  exit 0
fi

# Prefer kitout's Keychain-backed askpass (sudo = true) so unattended `apply -y`
# works; fall back to an interactive prompt when run standalone.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

sudo_cmd softwareupdate --schedule on

key_true AutomaticCheckEnabled   || sudo_cmd defaults write "$DOMAIN" AutomaticCheckEnabled -bool true
key_true AutomaticDownload       || sudo_cmd defaults write "$DOMAIN" AutomaticDownload -bool true
key_true ConfigDataInstall       || sudo_cmd defaults write "$DOMAIN" ConfigDataInstall -bool true
key_true CriticalUpdateInstall   || sudo_cmd defaults write "$DOMAIN" CriticalUpdateInstall -bool true

echo "Automatic security updates enabled."
