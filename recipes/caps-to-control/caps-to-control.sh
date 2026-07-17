#!/usr/bin/env bash
# Remap Caps Lock -> Left Control using hidutil, and persist it across reboots with
# a per-user LaunchAgent that re-applies the mapping at login.
#
# hidutil usage codes (HID page 0x7):
#   Caps Lock    = 0x700000039  (source)
#   Left Control = 0x7000000E0  (destination)
# hidutil's own remap is RUNTIME ONLY — it resets on reboot, which is why we install
# a LaunchAgent (RunAtLoad) to set it every login. No sudo: user-key remapping and
# ~/Library/LaunchAgents are user-scoped. Idempotent.
set -euo pipefail

LABEL="com.kitout.caps-to-control"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
SRC="0x700000039"   # Caps Lock     (hidutil --set wants hex)
DST="0x7000000E0"   # Left Control  (hidutil --set wants hex)
# hidutil --get prints usage codes in DECIMAL, so the read-back probe matches on
# these; keep in sync with SRC/DST above.
SRC_DEC="30064771129"  # 0x700000039
DST_DEC="30064771296"  # 0x7000000E0
MAPPING="{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":${SRC},\"HIDKeyboardModifierMappingDst\":${DST}}]}"

# Desired LaunchAgent content: run the hidutil remap once at login.
read -r -d '' PLIST_BODY <<EOF || true
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/hidutil</string>
    <string>property</string>
    <string>--set</string>
    <string>${MAPPING}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

# Read-only probes (match the step's check). "active" = both the Caps Lock source
# and the Left Control destination usage codes show up (in DECIMAL) in the current
# UserKeyMapping dump. hidutil --get renders codes in decimal, not the hex --set uses.
plist_ok()  { [ -f "$PLIST" ]; }
mapping_ok(){
  local m
  m="$(hidutil property --get 'UserKeyMapping' 2>/dev/null)" || return 1
  printf '%s' "$m" | grep -q "$SRC_DEC" && printf '%s' "$m" | grep -q "$DST_DEC"
}

if plist_ok && mapping_ok; then
  echo "Caps Lock -> Control already active and persisted."
  exit 0
fi

# Install / refresh the LaunchAgent plist (only rewrite if content differs).
mkdir -p "$HOME/Library/LaunchAgents"
if [ ! -f "$PLIST" ] || [ "$(cat "$PLIST")" != "$PLIST_BODY" ]; then
  printf '%s\n' "$PLIST_BODY" >"$PLIST"
  echo "Wrote LaunchAgent $PLIST."
fi

# Apply the mapping now so it takes effect without a logout. Reload the agent so
# its RunAtLoad definition is current (bootout may not exist yet — ignore errors).
launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST" 2>/dev/null || true
hidutil property --set "$MAPPING" >/dev/null

echo "Caps Lock -> Control applied and persisted (takes full effect on next login too)."
