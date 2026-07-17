#!/usr/bin/env bash
# Enable macOS's built-in application-layer firewall (ALF) and turn on stealth
# mode, via the socketfilterfw control tool that ships at:
#   /usr/libexec/ApplicationFirewall/socketfilterfw
# ALF filters INBOUND connections per-application (it is NOT the pf packet
# filter). Stealth mode makes the Mac ignore unsolicited probes (e.g. ICMP ping)
# so it doesn't advertise itself to port scanners.
# Needs sudo to change state (reading state is unprivileged). Idempotent.
set -euo pipefail

fw='/usr/libexec/ApplicationFirewall/socketfilterfw'

if [ ! -x "$fw" ]; then
  echo "socketfilterfw not found at $fw — unsupported macOS." >&2
  exit 1
fi

# Read-only probes (no privilege needed). Match the step's check.
state_on()   { "$fw" --getglobalstate  2>/dev/null | grep -q 'State = 1'; }
stealth_on() { "$fw" --getstealthmode  2>/dev/null | grep -q 'mode is on'; }

if state_on && stealth_on; then
  echo "Application firewall + stealth mode already enabled."
  exit 0
fi

# Prefer kitout's Keychain-backed askpass (sudo = true) so unattended `apply -y`
# works; fall back to an interactive prompt when run standalone.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

state_on   || sudo_cmd "$fw" --setglobalstate on   >/dev/null
stealth_on || sudo_cmd "$fw" --setstealthmode on   >/dev/null

echo "Application firewall + stealth mode enabled."
