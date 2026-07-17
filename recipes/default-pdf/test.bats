#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "default-pdf: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "default-pdf: sets the UTI handler and is idempotent (VM only)" {
  require_apply
  command -v duti >/dev/null || skip "duti not installed"
  osascript -e 'id of app "Preview"' >/dev/null 2>&1 || skip "Preview not installed on this runner"
  run bash "$WORK/steps/default-pdf.sh"
  [ "$status" -eq 0 ]
  [ "$(duti -d com.adobe.pdf)" = "com.apple.Preview" ]
  # idempotent: second run is a no-op and says so
  run bash "$WORK/steps/default-pdf.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already"* ]]
}
