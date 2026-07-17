#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "computer-name: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "computer-name: check probe reads scutil (read-only)" {
  # Safe: just confirm the probe mechanism resolves the current name without
  # changing anything. The apply RENAMES the machine, so it's VM-only and not
  # exercised here to avoid clobbering a real Mac's name under RECIPE_APPLY.
  run scutil --get LocalHostName
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}
