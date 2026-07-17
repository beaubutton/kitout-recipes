#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "rosetta: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "rosetta: no-op path is safe on Intel / when already installed" {
  # Safe to run anywhere: on Intel or an arm64 machine that already has Rosetta,
  # the script exits 0 without installing. (A fresh install is gated behind
  # RECIPE_APPLY and only meaningful on a Rosetta-less Apple Silicon box.)
  if [ "$(uname -m)" != "arm64" ] || [ -d /Library/Apple/usr/share/rosetta ]; then
    run bash "$WORK/steps/rosetta.sh"
    [ "$status" -eq 0 ]
    [[ "$output" == *"not needed"* || "$output" == *"already installed"* ]]
  else
    require_apply
    run bash "$WORK/steps/rosetta.sh"
    [ "$status" -eq 0 ]
    [ -d /Library/Apple/usr/share/rosetta ]
  fi
}
