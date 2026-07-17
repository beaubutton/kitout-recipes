#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "oh-my-zsh: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "oh-my-zsh: check probe is pending when absent, satisfied when present" {
  # Pure probe logic against an isolated HOME — no network, no installer run.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  run sh -c '[ -d "$HOME/.oh-my-zsh" ]'
  [ "$status" -ne 0 ]                       # not installed → pending
  mkdir -p "$HOME/.oh-my-zsh"
  run sh -c '[ -d "$HOME/.oh-my-zsh" ]'
  [ "$status" -eq 0 ]                       # present → satisfied
}

@test "oh-my-zsh: script no-ops when already installed (isolated HOME, no network)" {
  # Pre-create the framework dir so the script takes its fast idempotent exit
  # WITHOUT hitting the network or running the real installer.
  export HOME="$WORK/home"; mkdir -p "$HOME/.oh-my-zsh"
  run bash "$WORK/steps/oh-my-zsh.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}

@test "oh-my-zsh: apply installs the framework and is idempotent (network, VM only)" {
  require_apply
  command -v git >/dev/null || skip "git not installed on this runner"
  export HOME="$WORK/home"; mkdir -p "$HOME"
  run bash "$WORK/steps/oh-my-zsh.sh"
  [ "$status" -eq 0 ]
  [ -d "$HOME/.oh-my-zsh" ]
  # second run: already-installed fast path, still 0
  run bash "$WORK/steps/oh-my-zsh.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}
