#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "reduce-transparency: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "reduce-transparency: apply sets the key and is idempotent (VM only — mutates real universalaccess)" {
  require_apply
  # Writes the logged-in user's real com.apple.universalaccess domain (no clean
  # per-HOME isolation for cfprefsd). Run on a throwaway machine only.
  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  [ "$(defaults read com.apple.universalaccess reduceTransparency)" = "1" ]

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
