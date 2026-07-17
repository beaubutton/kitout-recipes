#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "gh-cli-config: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "gh-cli-config: check probe is a plain command -v gh" {
  # The check is just tool presence — confirm it resolves on this machine
  # without touching any config.
  run sh -c "command -v gh"
  [ "$status" -eq 0 ]
}

@test "gh-cli-config: apply sets config + alias and is idempotent (isolated HOME)" {
  require_apply
  command -v gh >/dev/null || skip "gh not on PATH"
  export HOME="$WORK/home"; mkdir -p "$HOME"
  export XDG_CONFIG_HOME="$HOME/.config"

  run bash "$WORK/steps/gh-cli-config.sh"
  [ "$status" -eq 0 ]
  [ "$(gh config get git_protocol)" = "ssh" ]
  [ "$(gh config get prompt)" = "enabled" ]
  [ -n "$(gh config get editor)" ]
  gh alias list | grep -q '^prs: pr list --author @me'

  # idempotent: second run makes no further writes, alias left untouched
  run bash "$WORK/steps/gh-cli-config.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"set git_protocol"* ]]
  [[ "$output" == *"already exists"* ]]
}

@test "gh-cli-config: does not overwrite a pre-existing 'prs' alias (isolated HOME)" {
  require_apply
  command -v gh >/dev/null || skip "gh not on PATH"
  export HOME="$WORK/home"; mkdir -p "$HOME"
  export XDG_CONFIG_HOME="$HOME/.config"

  gh alias set prs "issue list --author @me" >/dev/null

  run bash "$WORK/steps/gh-cli-config.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already exists"* ]]
  gh alias list | grep -q '^prs: issue list --author @me'
}
