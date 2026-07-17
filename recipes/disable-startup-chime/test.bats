#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "disable-startup-chime: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "disable-startup-chime: check parses nvram output (fixture, no nvram write)" {
  # Exercise the '%01' grep against fixture strings written to files — the grep
  # pattern is exactly the one the step's check uses. Never writes NVRAM, no sudo.
  printf 'StartupMute\t%%01\n' >"$WORK/muted.txt"      # nvram-shaped: literal %01
  printf 'StartupMute\t%%00\n' >"$WORK/chime.txt"      # literal %00
  : >"$WORK/unset.txt"                                 # variable unset → empty

  run grep -q '%01' "$WORK/muted.txt"
  [ "$status" -eq 0 ]                                   # muted → satisfied
  run grep -q '%01' "$WORK/chime.txt"
  [ "$status" -ne 0 ]                                   # chime on → pending
  run grep -q '%01' "$WORK/unset.txt"
  [ "$status" -ne 0 ]                                   # unset → pending
}

@test "disable-startup-chime: apply mutes it and is idempotent (VM only — writes NVRAM)" {
  require_apply
  # Writes firmware NVRAM. Only run on a throwaway VM.
  run bash "$WORK/steps/disable-startup-chime.sh"
  [ "$status" -eq 0 ]
  run sh -c "nvram StartupMute | grep -q '%01'"
  [ "$status" -eq 0 ]
  # second run: already muted
  run bash "$WORK/steps/disable-startup-chime.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already muted"* ]]
}
