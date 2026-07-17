#!/usr/bin/env bash
# Install Rosetta 2 (Apple's Intel translation) on Apple Silicon, for the odd
# x86_64-only app. No-op on Intel Macs and when already installed. Idempotent.
set -euo pipefail

if [ "$(uname -m)" != "arm64" ]; then
  echo "Not Apple Silicon — Rosetta not needed."
  exit 0
fi

if [ -d /Library/Apple/usr/share/rosetta ]; then
  echo "Rosetta already installed."
  exit 0
fi

# --agree-to-license accepts Apple's SLA non-interactively. Runs as the normal
# user (softwareupdate holds the entitlement); no sudo needed.
softwareupdate --install-rosetta --agree-to-license
echo "Rosetta 2 installed."
