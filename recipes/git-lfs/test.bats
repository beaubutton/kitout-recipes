#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "git-lfs: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "git-lfs: apply installs the filter and is idempotent" {
  require_apply
  command -v git-lfs >/dev/null || skip "git-lfs not installed on this runner"
  # Isolate global git config so we don't touch the tester's real ~/.gitconfig.
  export HOME="$WORK/home"; mkdir -p "$HOME"

  run bash "$WORK/steps/git-lfs.sh"; [ "$status" -eq 0 ]
  run git config --global --get filter.lfs.clean; [ "$status" -eq 0 ]

  # Idempotent: second run reports already-enabled, still exit 0.
  run bash "$WORK/steps/git-lfs.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already enabled"* ]]
}
