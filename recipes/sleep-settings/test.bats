#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "sleep-settings: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "sleep-settings: check awk logic parses pmset output (fixture, no pmset write)" {
  # Feed the awk the same shape `pmset -g custom` emits and confirm satisfied /
  # pending outcomes. Pure parsing — never calls pmset, never needs sudo.
  AWK='$1=="displaysleep"{d=$2} $1=="disksleep"{k=$2} $1=="powernap"{p=$2} END{exit !(d==10 && k==10 && p==0)}'

  printf ' displaysleep 10\n disksleep 10\n powernap 0\n' >"$WORK/ok.txt"
  run sh -c "awk '$AWK' '$WORK/ok.txt'"
  [ "$status" -eq 0 ]                                   # converged → satisfied

  printf ' displaysleep 5\n disksleep 10\n powernap 0\n' >"$WORK/bad_display.txt"
  run sh -c "awk '$AWK' '$WORK/bad_display.txt'"
  [ "$status" -ne 0 ]                                   # wrong displaysleep → pending

  printf ' displaysleep 10\n disksleep 10\n powernap 1\n' >"$WORK/bad_nap.txt"
  run sh -c "awk '$AWK' '$WORK/bad_nap.txt'"
  [ "$status" -ne 0 ]                                   # powernap on → pending
}

@test "sleep-settings: apply sets the timers and is idempotent (VM only — changes power policy)" {
  require_apply
  # Mutates system-wide power management. Only run on a throwaway VM.
  run bash "$WORK/steps/sleep-settings.sh"
  [ "$status" -eq 0 ]
  run sh -c "pmset -g custom | awk '\$1==\"displaysleep\"{d=\$2} \$1==\"disksleep\"{k=\$2} \$1==\"powernap\"{p=\$2} END{exit !(d==10 && k==10 && p==0)}'"
  [ "$status" -eq 0 ]
  # second run: already applied
  run bash "$WORK/steps/sleep-settings.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already applied"* ]]
}
