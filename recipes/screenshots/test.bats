#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "screenshots: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "screenshots: apply routes captures and is idempotent (VM only)" {
  require_apply
  # Isolate HOME so the created ~/Screenshots dir lands in the temp tree. NOTE:
  # `defaults` writes hit the real per-user cfprefsd domain regardless of HOME,
  # so this still mutates com.apple.screencapture — run on a VM only.
  export HOME="$WORK/home"; mkdir -p "$HOME"

  run bash "$WORK/steps/screenshots.sh"
  [ "$status" -eq 0 ]
  [ -d "$HOME/Screenshots" ]
  [ "$(defaults read com.apple.screencapture location)" = "$HOME/Screenshots" ]
  [ "$(defaults read com.apple.screencapture disable-shadow)" = "1" ]
  [ "$(defaults read com.apple.screencapture type)" = "png" ]

  # idempotent: second run reports already-applied, still exit 0
  run bash "$WORK/steps/screenshots.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already applied"* ]]
}
