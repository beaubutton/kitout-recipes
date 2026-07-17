#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "filevault-enable: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "filevault-enable: check probe reads real fdesetup status (read-only, no state change)" {
  # Safe anywhere: fdesetup status is a read-only query. We only assert the
  # probe mechanism resolves without error; we never assert a particular
  # On/Off value since CI runners' FileVault state is out of our control and
  # this recipe must never toggle it in CI.
  command -v fdesetup >/dev/null || skip "fdesetup not present on this platform"
  run fdesetup status
  [ "$status" -eq 0 ]
  [[ "$output" == *"FileVault is"* ]]
}

@test "filevault-enable: check probe string-matching logic (fixture, no state change)" {
  run sh -c "printf 'FileVault is On.\n' | grep -q 'FileVault is On'"
  [ "$status" -eq 0 ]
  run sh -c "printf 'FileVault is Off.\n' | grep -q 'FileVault is On'"
  [ "$status" -ne 0 ]
}

@test "filevault-enable: apply enables FileVault (VM/real-machine only — NEVER run in CI)" {
  require_apply
  # This is deliberately never exercised even under RECIPE_APPLY in a CI
  # context: fdesetup enable is interactive (prompts for a password) and
  # prints a one-time, unrecoverable-if-lost recovery key, then begins
  # encrypting the real startup disk on next reboot. There is no dummy
  # fixture for "the startup volume" — this effect is real-machine/VM-only
  # and must be run by a human watching the terminal, never unattended.
  skip "fdesetup enable is interactive + irreversible-if-mishandled — verify by hand on a real Mac or VM, never in automated CI"
}
