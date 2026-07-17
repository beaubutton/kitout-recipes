#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "pre-commit-global: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "pre-commit-global: check probe flips with init.templateDir (isolated HOME)" {
  # Pure probe logic in an isolated HOME — never touches the tester's real git config.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  probe='[ -n "$(git config --global --get init.templateDir 2>/dev/null)" ]'
  run sh -c "$probe"
  [ "$status" -ne 0 ]                                   # clean → pending
  git config --global init.templateDir "$HOME/.config/git/template"
  run sh -c "$probe"
  [ "$status" -eq 0 ]                                   # set → satisfied
}

@test "pre-commit-global: refuses to run without pre-commit on PATH (safe, no state change)" {
  # Exercise the missing-tool guard without a real PATH mutation risk: run
  # with an empty PATH override (still resolves core builtins via `command`,
  # git/pre-commit will not be found), asserting the script fails loudly
  # rather than silently no-op'ing.
  run env PATH="/usr/bin:/bin" bash -c '
    command -v pre-commit >/dev/null 2>&1 && exit 0
    bash "'"$WORK"'/steps/pre-commit-global.sh"
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"pre-commit not found"* ]]
}

@test "pre-commit-global: apply configures template dir and is idempotent (isolated HOME)" {
  require_apply
  command -v pre-commit >/dev/null || skip "pre-commit not on PATH"
  export HOME="$WORK/home"; mkdir -p "$HOME"

  run bash "$WORK/steps/pre-commit-global.sh"
  [ "$status" -eq 0 ]
  [ "$(git config --global --get init.templateDir)" = "$HOME/.config/git/template" ]
  [ -d "$HOME/.config/git/template/hooks" ]

  # idempotent: second run reports already-configured, no re-templating noise
  run bash "$WORK/steps/pre-commit-global.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already configured"* ]]
}
