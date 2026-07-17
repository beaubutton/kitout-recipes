#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "accent-color: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "accent-color: apply sets the keys and is idempotent (VM only — mutates real NSGlobalDomain)" {
  require_apply
  # This writes the logged-in user's real accent color (NSGlobalDomain is the
  # global domain; there's no clean per-HOME isolation for cfprefsd). Run on a
  # throwaway machine only.
  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  [ "$(defaults read -g AppleAccentColor)" = "4" ]
  [ "$(defaults read -g AppleAquaColorVariant)" = "1" ]

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
