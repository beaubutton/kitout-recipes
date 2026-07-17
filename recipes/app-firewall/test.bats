#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "app-firewall: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "app-firewall: check probe parses socketfilterfw output (fixture, no state change)" {
  # Pure probe logic against fixture strings — never toggles the real firewall.
  fw_state() { printf 'Firewall is enabled. (State = 1)\n'; }
  run sh -c "fw_state() { printf 'Firewall is enabled. (State = 1)\n'; }; fw_state | grep -q 'State = 1'"
  [ "$status" -eq 0 ]                                   # enabled → matches
  run sh -c "printf 'Firewall is disabled. (State = 0)\n' | grep -q 'State = 1'"
  [ "$status" -ne 0 ]                                   # disabled → no match
  run sh -c "printf 'Firewall stealth mode is on\n' | grep -q 'mode is on'"
  [ "$status" -eq 0 ]                                   # stealth on → matches
  run sh -c "printf 'Firewall stealth mode is off\n' | grep -q 'mode is on'"
  [ "$status" -ne 0 ]                                   # stealth off → no match
}

@test "app-firewall: apply enables it and is idempotent (VM only — changes system state)" {
  require_apply
  # Mutates the machine's firewall. Only run on a throwaway VM.
  fw='/usr/libexec/ApplicationFirewall/socketfilterfw'
  [ -x "$fw" ] || skip "socketfilterfw not present"

  run bash "$WORK/steps/app-firewall.sh"
  [ "$status" -eq 0 ]
  run sh -c "$fw --getglobalstate | grep -q 'State = 1'"
  [ "$status" -eq 0 ]
  run sh -c "$fw --getstealthmode | grep -q 'mode is on'"
  [ "$status" -eq 0 ]

  # second run: already-enabled, still 0
  run bash "$WORK/steps/app-firewall.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already enabled"* ]]
}
