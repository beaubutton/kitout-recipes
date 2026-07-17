#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "default-terminal: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "default-terminal: sets the UTI handler and is idempotent (VM only)" {
  require_apply
  command -v duti >/dev/null || skip "duti not installed"
  osascript -e 'id of app "Ghostty"' >/dev/null 2>&1 || skip "Ghostty not installed on this runner"
  run bash "$WORK/steps/default-terminal.sh"
  [ "$status" -eq 0 ]
  [ "$(duti -d public.unix-executable)" = "com.mitchellh.ghostty" ]
  # idempotent
  run bash "$WORK/steps/default-terminal.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already"* ]]
}
