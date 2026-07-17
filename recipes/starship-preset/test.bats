#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "starship-preset: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "starship-preset: check probe tracks the config file (isolated HOME)" {
  export HOME="$WORK/home"; unset XDG_CONFIG_HOME; mkdir -p "$HOME/.config"
  cfg="$HOME/.config/starship.toml"
  run sh -c '[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ]'
  [ "$status" -ne 0 ]                       # absent → pending
  : >"$cfg"
  run sh -c '[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml" ]'
  [ "$status" -eq 0 ]                       # present → satisfied
}

@test "starship-preset: script leaves an existing config untouched (no starship needed)" {
  # Seed semantics: a pre-existing config short-circuits before we ever call
  # starship, so this runs even on a runner without the binary.
  export HOME="$WORK/home"; unset XDG_CONFIG_HOME; mkdir -p "$HOME/.config"
  printf '# my hand-tuned prompt\n' >"$HOME/.config/starship.toml"
  run bash "$WORK/steps/starship-preset.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"leaving it untouched"* ]]
  grep -q 'hand-tuned' "$HOME/.config/starship.toml"   # not overwritten
}

@test "starship-preset: apply renders a preset and is idempotent (needs starship, VM only)" {
  require_apply
  command -v starship >/dev/null || skip "starship not installed on this runner"
  export HOME="$WORK/home"; unset XDG_CONFIG_HOME; mkdir -p "$HOME"
  run bash "$WORK/steps/starship-preset.sh"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.config/starship.toml" ]
  # second run: config exists → untouched, still 0
  run bash "$WORK/steps/starship-preset.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"untouched"* ]]
}
