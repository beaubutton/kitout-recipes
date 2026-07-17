#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "colima: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "colima: apply boots the VM and is idempotent (VM/runner with virtualization)" {
  # Booting a real VM is heavy and state-mutating — gate it behind RECIPE_APPLY.
  require_apply
  command -v colima >/dev/null || skip "colima not installed on this runner"

  run bash "$WORK/steps/colima.sh"
  [ "$status" -eq 0 ]
  run colima status
  [ "$status" -eq 0 ]                     # VM is up

  # Idempotent: second run sees it running, reports so, still exit 0, no reboot.
  run bash "$WORK/steps/colima.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already running"* ]]
}
