#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "three-finger-drag: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "three-finger-drag: apply sets the keys and is idempotent" {
  require_apply
  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  [ "$(defaults read com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag)" = "1" ]
  [ "$(defaults read com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag)" = "1" ]
  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json 2>/dev/null | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
