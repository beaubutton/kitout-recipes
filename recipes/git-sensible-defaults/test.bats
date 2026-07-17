#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "git-sensible-defaults: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "git-sensible-defaults: applies keys and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"

  run bash "$WORK/steps/git-sensible-defaults.sh"
  [ "$status" -eq 0 ]
  [ "$(git config --global --get init.defaultBranch)" = "main" ]
  [ "$(git config --global --get rerere.enabled)" = "true" ]

  # idempotent: second run reports no per-key changes
  run bash "$WORK/steps/git-sensible-defaults.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"set init.defaultBranch"* ]]
}
