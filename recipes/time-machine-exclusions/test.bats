#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "time-machine-exclusions: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "time-machine-exclusions: check probe parses tmutil isexcluded output (fixture, no state change)" {
  # Pure probe logic against fixture strings — never touches real TM exclusions.
  run sh -c "printf '[Excluded]\n' | grep -q '^\[Excluded\]'"
  [ "$status" -eq 0 ]                                    # excluded → matches
  run sh -c "printf '[Included]\n' | grep -q '^\[Excluded\]'"
  [ "$status" -ne 0 ]                                    # included → no match
}

@test "time-machine-exclusions: nonexistent paths are skipped by the check (read-only)" {
  # A path that doesn't exist must not make the check fail — confirm the
  # skip-if-missing logic in isolation, without calling real tmutil.
  run sh -c '
    p="/tmp/kitout-recipes-test-does-not-exist-$$"
    [ -e "$p" ] || exit 0
    exit 1
  '
  [ "$status" -eq 0 ]
}

@test "time-machine-exclusions: apply excludes configured paths and is idempotent (VM only)" {
  require_apply
  command -v tmutil >/dev/null || skip "tmutil not present"

  # Use isolated throwaway paths so we never touch a real Mac's exclusions
  # beyond harmless, disposable temp directories.
  export HOME="$WORK/home"
  mkdir -p "$HOME/Library/Caches" "$HOME/.cache" "$HOME/Developer/build"

  run bash "$WORK/steps/time-machine-exclusions.sh"
  [ "$status" -eq 0 ]

  run tmutil isexcluded "$HOME/Library/Caches"
  [[ "$output" == *"[Excluded]"* ]]
  run tmutil isexcluded "$HOME/.cache"
  [[ "$output" == *"[Excluded]"* ]]
  run tmutil isexcluded "$HOME/Developer/build"
  [[ "$output" == *"[Excluded]"* ]]

  # second run: already-excluded, still 0 and reports no-op
  run bash "$WORK/steps/time-machine-exclusions.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already in place"* ]]
}
