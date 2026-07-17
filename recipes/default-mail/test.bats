#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "default-mail: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "default-mail: apply is GUI-gated (verify manually)" {
  # Changing the mailto: default can trigger macOS's consent dialog, which can't
  # be automated. There's nothing safe to assert headlessly — the step is
  # on-error = warn precisely because of this. Verified by hand.
  skip "GUI-gated: run the script, confirm the macOS dialog, then check 'duti -d mailto'"
}
