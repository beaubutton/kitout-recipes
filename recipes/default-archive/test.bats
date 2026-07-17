#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "default-archive: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "default-archive: sets the UTI handler and is idempotent (VM only)" {
  require_apply
  command -v duti >/dev/null || skip "duti not installed"
  osascript -e 'id of app "Keka"' >/dev/null 2>&1 || skip "Keka not installed on this runner"
  run bash "$WORK/steps/default-archive.sh"
  [ "$status" -eq 0 ]
  [ "$(duti -d public.zip-archive)" = "com.aone.keka" ]
  # idempotent: second run is a no-op and says so
  run bash "$WORK/steps/default-archive.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already"* ]]
}
