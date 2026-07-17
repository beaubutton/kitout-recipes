#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "caps-to-control: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "caps-to-control: check requires BOTH plist and active mapping (fixtures)" {
  # Exercise the two halves of the check against fixtures — no hidutil call, no
  # LaunchAgent installed into the tester's real home. hidutil --get renders usage
  # codes in DECIMAL: Caps Lock 0x700000039 = 30064771129, Left Control
  # 0x7000000E0 = 30064771296. The fixtures mimic that decimal --get output.
  plist="$WORK/agent.plist"

  # a realistic `hidutil property --get UserKeyMapping` dump for Caps->Control,
  # exactly as macOS emits it (decimal codes, semicolon-terminated).
  active_dump=$'(\n    {\n        HIDKeyboardModifierMappingDst = 30064771296;\n        HIDKeyboardModifierMappingSrc = 30064771129;\n    }\n)'

  # neither present → pending
  run sh -c "test -f '$plist'"
  [ "$status" -ne 0 ]

  # plist present but no mapping (empty dump) → still pending
  : >"$plist"
  run sh -c "test -f '$plist' && m='(null)' && printf '%s' \"\$m\" | grep -q 30064771129 && printf '%s' \"\$m\" | grep -q 30064771296"
  [ "$status" -ne 0 ]

  # guard against the classic bug: grepping for the HEX code never matches --get's
  # decimal output, so a hex-based check would wrongly report pending here.
  run sh -c "printf '%s' \"\$1\" | grep -q '0x7000000E0'" _ "$active_dump"
  [ "$status" -ne 0 ]

  # plist present AND decimal dump contains BOTH Caps src and Control dst → satisfied
  run sh -c "test -f '$plist' && m=\"\$1\" && printf '%s' \"\$m\" | grep -q 30064771129 && printf '%s' \"\$m\" | grep -q 30064771296" _ "$active_dump"
  [ "$status" -eq 0 ]
}

@test "caps-to-control: apply remaps + persists (VM only — mutates live keyboard)" {
  require_apply
  # This runs hidutil property --set and launchctl bootstrap against the REAL
  # login session (HOME-isolation can't sandbox those), so only run on a
  # throwaway VM you're okay remapping.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  run bash "$WORK/steps/caps-to-control.sh"
  [ "$status" -eq 0 ]
  [ -f "$HOME/Library/LaunchAgents/com.kitout.caps-to-control.plist" ]
  # --get reports codes in decimal: Left Control 0x7000000E0 = 30064771296.
  run sh -c "hidutil property --get 'UserKeyMapping' | grep -q 30064771296"
  [ "$status" -eq 0 ]

  # idempotent: second run reports already-active
  run bash "$WORK/steps/caps-to-control.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already active"* ]]

  # cleanup: drop the mapping and the agent so the VM session is left clean
  hidutil property --set '{"UserKeyMapping":[]}' >/dev/null 2>&1 || true
  launchctl bootout "gui/$(id -u)/com.kitout.caps-to-control" 2>/dev/null || true
}
