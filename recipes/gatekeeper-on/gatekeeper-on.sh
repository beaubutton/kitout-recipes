#!/usr/bin/env bash
# Ensure Gatekeeper (macOS's code-signing/notarization gate on running
# downloaded apps) is ENABLED, via `spctl --master-enable`. This script only
# ever turns Gatekeeper ON — it never disables it. Idempotent: no-ops once
# already enabled. Needs sudo.
#
# Some recent macOS releases/configurations (notably certain Apple Silicon
# security-policy states) require toggling Gatekeeper from Recovery mode
# rather than `spctl`; if `--master-enable` doesn't stick, see this recipe's
# README for the Recovery-mode path.
set -euo pipefail

# Read-only probe (no privilege needed). Matches the step's check.
gatekeeper_on() { spctl --status 2>/dev/null | grep -q 'assessments enabled'; }

if gatekeeper_on; then
  echo "Gatekeeper already enabled."
  exit 0
fi

# Prefer kitout's Keychain-backed askpass (sudo = true); fall back to a prompt.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

sudo_cmd spctl --master-enable

if gatekeeper_on; then
  echo "Gatekeeper enabled."
else
  echo "spctl --master-enable did not stick — this Mac may require enabling Gatekeeper from Recovery mode." >&2
  exit 1
fi
