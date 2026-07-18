#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "tap-to-click: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "tap-to-click: apply sets the keys and is idempotent" {
  require_apply
  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  [ "$(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking)" = "1" ]
  [ "$(defaults read com.apple.AppleMultitouchTrackpad Clicking)" = "1" ]
  [ "$(defaults read NSGlobalDomain com.apple.mouse.tapBehavior)" = "1" ]
  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json 2>/dev/null | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
