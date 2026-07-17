#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "default-browser: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "default-browser: apply is GUI-gated (verify manually)" {
  # Setting the default browser requires clicking macOS's consent dialog, which
  # can't be automated. There's nothing safe to assert headlessly — the step is
  # on-error = warn precisely because of this. Verified by hand.
  skip "GUI-gated: confirm the macOS dialog and re-check 'defaultbrowser'"
}
