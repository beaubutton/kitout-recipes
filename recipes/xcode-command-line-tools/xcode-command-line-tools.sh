#!/usr/bin/env bash
# Ensure the Xcode Command Line Tools (clang, make, git, headers — the base
# compiler toolchain most other dev tooling assumes) are installed.
#
# Prefers the unattended `softwareupdate` trick (no GUI, works over SSH/CI):
# drop a sentinel file that makes CLTs show up in `softwareupdate --list`,
# find the CLT label, install it non-interactively, then clean up the
# sentinel. Falls back to `xcode-select --install`, which pops the normal
# GUI installer, if the softwareupdate path doesn't turn up a label (e.g. a
# macOS version where Apple changed the trick, or no sudo available).
# Idempotent: exits fast if the tools are already present.
set -euo pipefail

SENTINEL="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

# Prefer kitout's Keychain-backed askpass (sudo = true); fall back to a prompt.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

if xcode-select -p >/dev/null 2>&1; then
  echo "Xcode Command Line Tools already installed."
  exit 0
fi

cleanup() { sudo_cmd rm -f "$SENTINEL" 2>/dev/null || rm -f "$SENTINEL" 2>/dev/null || true; }
trap cleanup EXIT

# Drop the sentinel. /tmp is world-writable on macOS, so a plain touch is
# enough; only reach for sudo if that somehow fails. Never let a failed touch
# (e.g. sudo unavailable) abort before the GUI fallback below.
touch "$SENTINEL" 2>/dev/null || sudo_cmd touch "$SENTINEL" 2>/dev/null || true

label="$( (softwareupdate --list 2>/dev/null || true) |
  grep -E '^\* Label: Command Line Tools' |
  sed 's/^\* Label: //' |
  tail -1 || true)"

if [ -n "$label" ]; then
  echo "Installing: $label"
  if sudo_cmd softwareupdate --install "$label" --verbose; then
    echo "Xcode Command Line Tools installed."
    exit 0
  fi
  echo "Unattended softwareupdate install failed; falling back to xcode-select --install (GUI)." >&2
else
  echo "No Command Line Tools label found via softwareupdate; falling back to xcode-select --install (GUI)." >&2
fi

cleanup
trap - EXIT

# GUI fallback: pops Apple's installer dialog. Not scriptable to completion —
# the user must click through it.
xcode-select --install
echo "Xcode Command Line Tools install started via GUI — follow the on-screen prompts."
