#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "git-conditional-identity: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "git-conditional-identity: check probe flips with includeIf (isolated HOME)" {
  # Pure probe logic in an isolated HOME — never touches the tester's real git config.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  probe='[ -n "$(git config --global --get "includeIf.gitdir:~/work/.path" 2>/dev/null)" ]'
  run sh -c "$probe"
  [ "$status" -ne 0 ]                                   # clean → pending
  git config --global "includeIf.gitdir:~/work/.path" "~/.gitconfig-work"
  run sh -c "$probe"
  [ "$status" -eq 0 ]                                   # set → satisfied
}

@test "git-conditional-identity: apply configures identity + includeIf and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"

  run bash "$WORK/steps/git-conditional-identity.sh"
  [ "$status" -eq 0 ]
  [ -n "$(git config --global --get user.name)" ]
  [ -n "$(git config --global --get user.email)" ]
  [ "$(git config --global --get "includeIf.gitdir:~/work/.path")" = "~/.gitconfig-work" ]
  [ -f "$HOME/.gitconfig-work" ]
  grep -q '\[user\]' "$HOME/.gitconfig-work"
  [ -d "$HOME/work" ]

  # idempotent: gitconfig-work isn't rewritten, second run reports already-configured
  before="$(cat "$HOME/.gitconfig-work")"
  run bash "$WORK/steps/git-conditional-identity.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already configured"* ]]
  [ "$(cat "$HOME/.gitconfig-work")" = "$before" ]
}
