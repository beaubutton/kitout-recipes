#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "remote-login-off: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "remote-login-off: check probe string-matching logic (fixture, no state change)" {
  run sh -c "printf 'Remote Login: Off\n' | grep -qi 'Remote Login: Off'"
  [ "$status" -eq 0 ]
  run sh -c "printf 'Remote Login: On\n' | grep -qi 'Remote Login: Off'"
  [ "$status" -ne 0 ]
}

@test "remote-login-off: check probe reads real systemsetup state (read-only, no state change)" {
  # Safe anywhere: -getremotelogin is a query, never a write. We run it
  # UNPRIVILEGED here (never sudo in tests) precisely to document why the real
  # check uses `sudo -n`: on modern macOS `systemsetup` requires admin even to
  # READ and prints "You need administrator access..." with exit 0 when
  # unprivileged — so an unprivileged probe can never see "Off". We only assert
  # the mechanism resolves without crashing; we don't assert an On/Off value.
  command -v systemsetup >/dev/null || skip "systemsetup not present on this platform"
  run systemsetup -getremotelogin
  [[ "$output" == *"Remote Login"* || "$output" == *"administrator access"* || "$status" -ne 0 ]]
}

@test "remote-login-off: apply turns off Remote Login and is idempotent (VM only — changes system SSH server state)" {
  require_apply
  # Mutates the machine's SSH server availability. Only run on a throwaway VM
  # you do not depend on SSHing into.
  run bash "$WORK/steps/remote-login-off.sh"
  [ "$status" -eq 0 ]

  run systemsetup -getremotelogin
  [[ "$output" == *"Off"* ]]

  # second run: already-off, still 0 and reports so
  run bash "$WORK/steps/remote-login-off.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already off"* ]]
}
