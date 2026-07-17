#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "default-editor: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "default-editor: sets the UTI handlers and is idempotent (VM only)" {
  require_apply
  command -v duti >/dev/null || skip "duti not installed"
  osascript -e 'id of app "Visual Studio Code"' >/dev/null 2>&1 || skip "VS Code not installed on this runner"
  run bash "$WORK/steps/default-editor.sh"
  [ "$status" -eq 0 ]
  [ "$(duti -d public.plain-text)" = "com.microsoft.VSCode" ]
  [ "$(duti -d public.source-code)" = "com.microsoft.VSCode" ]
  # idempotent: second run is a no-op and says so
  run bash "$WORK/steps/default-editor.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already"* ]]
}
