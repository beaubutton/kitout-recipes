#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "gitignore-global: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "gitignore-global: installs the file + key and is idempotent (isolated HOME)" {
  require_apply
  # Isolate everything git touches so we never write the tester's real config.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  export XDG_CONFIG_HOME="$HOME/.config"

  # Clean state → check is pending (no excludesfile set yet).
  run sh -c 'f="$(git config --global --get core.excludesfile 2>/dev/null)"; [ -n "$f" ] && [ -f "$f" ]'
  [ "$status" -ne 0 ]

  run bash "$WORK/steps/gitignore-global.sh"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/git/ignore" ]
  grep -q '\.DS_Store' "$HOME/.config/git/ignore"
  [ "$(git config --global --get core.excludesfile)" = "$HOME/.config/git/ignore" ]

  # check now satisfied
  run sh -c 'f="$(git config --global --get core.excludesfile 2>/dev/null)"; [ -n "$f" ] && [ -f "$f" ]'
  [ "$status" -eq 0 ]

  # idempotent: second run reports already-installed, no rewrite
  run bash "$WORK/steps/gitignore-global.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}
