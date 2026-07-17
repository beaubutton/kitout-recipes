#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "git-delta: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "git-delta: check probe flips with core.pager" {
  export HOME="$WORK/home"; mkdir -p "$HOME"
  probe='[ "$(git config --global --get core.pager 2>/dev/null)" = "delta" ]'
  run sh -c "$probe"
  [ "$status" -ne 0 ]                                   # clean → pending
  git config --global core.pager delta
  run sh -c "$probe"
  [ "$status" -eq 0 ]                                   # set → satisfied
}

@test "git-delta: apply wires delta and is idempotent (isolated HOME)" {
  require_apply
  command -v delta >/dev/null || skip "delta (git-delta) not installed on this runner"
  export HOME="$WORK/home"; mkdir -p "$HOME"

  run bash "$WORK/steps/git-delta.sh"
  [ "$status" -eq 0 ]
  [ "$(git config --global --get core.pager)" = "delta" ]
  [ "$(git config --global --get interactive.diffFilter)" = "delta --color-only" ]
  [ "$(git config --global --get delta.navigate)" = "true" ]

  # idempotent: second run makes no per-key changes
  run bash "$WORK/steps/git-delta.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"set core.pager"* ]]
}
