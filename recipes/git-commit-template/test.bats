#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "git-commit-template: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "git-commit-template: check probe flips with commit.template (isolated HOME)" {
  # Pure probe logic in an isolated HOME — never touches the tester's real git config.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  probe='[ -n "$(git config --global --get commit.template 2>/dev/null)" ]'
  run sh -c "$probe"
  [ "$status" -ne 0 ]                                   # clean → pending
  git config --global commit.template "$HOME/.gitmessage"
  run sh -c "$probe"
  [ "$status" -eq 0 ]                                   # set → satisfied
}

@test "git-commit-template: apply writes the template + config and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"

  run bash "$WORK/steps/git-commit-template.sh"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.gitmessage" ]
  grep -q 'kitout:git-commit-template' "$HOME/.gitmessage"
  grep -q 'feat     — a new feature' "$HOME/.gitmessage"
  [ "$(git config --global --get commit.template)" = "$HOME/.gitmessage" ]

  # idempotent: second run reports already-configured, file content unchanged
  before="$(cat "$HOME/.gitmessage")"
  run bash "$WORK/steps/git-commit-template.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already configured"* ]]
  [ "$(cat "$HOME/.gitmessage")" = "$before" ]
}

@test "git-commit-template: leaves a foreign ~/.gitmessage untouched (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"
  printf 'My own template, not managed by kitout.\n' >"$HOME/.gitmessage"

  run bash "$WORK/steps/git-commit-template.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"isn't managed by this recipe"* ]]
  [ "$(cat "$HOME/.gitmessage")" = "My own template, not managed by kitout." ]
  # still wires up the config, even though the file itself was left alone
  [ "$(git config --global --get commit.template)" = "$HOME/.gitmessage" ]
}
