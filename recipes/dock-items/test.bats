#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "dock-items: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "dock-items: membership probe matches labels exactly (fixture, no Dock touched)" {
  # Simulate dockutil --list output (tab-separated) and exercise the same
  # cut -f1 | grep -qxF logic the script and check use. Never touches the Dock.
  list="$WORK/list.txt"
  printf 'Visual Studio Code\t/Applications/Visual Studio Code.app\tfoo\n' >"$list"
  printf 'Music\t/System/Applications/Music.app\tbar\n' >>"$list"

  run sh -c "cut -f1 '$list' | grep -qxF 'Visual Studio Code'"
  [ "$status" -eq 0 ]                                   # present → match
  run sh -c "cut -f1 '$list' | grep -qxF 'Music'"
  [ "$status" -eq 0 ]                                   # present → match
  run sh -c "cut -f1 '$list' | grep -qxF 'Xcode'"
  [ "$status" -ne 0 ]                                   # absent → no match
  # A substring must NOT match (exact whole-line only).
  run sh -c "cut -f1 '$list' | grep -qxF 'Music '"
  [ "$status" -ne 0 ]
}

@test "dock-items: apply curates the Dock and is idempotent (VM only — mutates YOUR Dock)" {
  require_apply
  command -v dockutil >/dev/null || skip "dockutil not installed on this runner"
  # This mutates the running user's real Dock. Only meaningful on a throwaway VM
  # where that's acceptable; there's no user-owned dummy Dock to target safely.
  run bash "$WORK/steps/dock-items.sh"
  [ "$status" -eq 0 ]
  # second run: nothing to do
  run bash "$WORK/steps/dock-items.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already curated"* ]]
}
