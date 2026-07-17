#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "dark-mode-auto: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "dark-mode-auto: script rejects an unknown MODE" {
  # Pure argument-parsing check — no appearance change, CI-safe.
  run env MODE=bogus bash "$WORK/steps/dark-mode-auto.sh"
  [ "$status" -eq 2 ]
  [[ "$output" == *"Unknown MODE"* ]]
}

@test "dark-mode-auto: apply sets Auto and is idempotent (VM / manual-verify only)" {
  require_apply
  # GUI-gated: the osascript live-switch can raise an Automation consent prompt,
  # and `defaults -g` writes the logged-in user's real appearance. Only run this
  # on a throwaway machine, then eyeball System Settings > Appearance = Auto.
  run env MODE=auto bash "$WORK/steps/dark-mode-auto.sh"
  [ "$status" -eq 0 ]
  [ "$(defaults read -g AppleInterfaceStyleSwitchesAutomatically 2>/dev/null)" = "1" ]

  # idempotent: second run reports already-Auto, still exit 0.
  run env MODE=auto bash "$WORK/steps/dark-mode-auto.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already Auto"* ]]
}
