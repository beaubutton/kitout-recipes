#!/usr/bin/env bash
# Configure macOS sleep behavior with pmset, applied to ALL power sources (-a):
#   displaysleep  — minutes of idle before the DISPLAY sleeps
#   disksleep     — minutes of idle before spinning disks sleep
#   powernap      — 0 disables Power Nap (background wakes for mail/updates/Time
#                   Machine while asleep)
# Values are minutes; 0 = never. Needs sudo to WRITE (reading is unprivileged).
# Idempotent: reads `pmset -g custom` and only writes what differs.
#
# Edit DISPLAYSLEEP / DISKSLEEP / POWERNAP below and mirror them into the check.
set -euo pipefail

DISPLAYSLEEP=10   # minutes
DISKSLEEP=10      # minutes
POWERNAP=0        # 0 = off, 1 = on

# Read effective per-source config (unprivileged). pmset -g custom prints both
# "AC Power" and "Battery Power" blocks; since we write with -a, the last value
# seen for each key reflects what we set.
read_val() { pmset -g custom 2>/dev/null | awk -v k="$1" '$1==k{v=$2} END{print v}'; }

cur_d="$(read_val displaysleep)"
cur_k="$(read_val disksleep)"
cur_p="$(read_val powernap)"

if [ "$cur_d" = "$DISPLAYSLEEP" ] && [ "$cur_k" = "$DISKSLEEP" ] && [ "$cur_p" = "$POWERNAP" ]; then
  echo "Sleep settings already applied (displaysleep=$DISPLAYSLEEP disksleep=$DISKSLEEP powernap=$POWERNAP)."
  exit 0
fi

# Prefer kitout's Keychain-backed askpass (sudo = true); fall back to a prompt.
sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

sudo_cmd pmset -a displaysleep "$DISPLAYSLEEP"
sudo_cmd pmset -a disksleep "$DISKSLEEP"
sudo_cmd pmset -a powernap "$POWERNAP"

echo "Sleep settings applied (displaysleep=$DISPLAYSLEEP disksleep=$DISKSLEEP powernap=$POWERNAP)."
