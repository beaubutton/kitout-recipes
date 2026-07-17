#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "debloat-apple-apps: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "debloat-apple-apps: absent removes a present target and is idempotent (dummy fixture)" {
  require_apply
  # NEVER test against a real app. Build a throwaway bundle and a manifest that
  # targets it, exercising the same `absent` pattern the recipe uses. No sudo —
  # the fixture is user-owned.
  dummy="$WORK/Fixture.app"; mkdir -p "$dummy/Contents"
  cat >"$WORK/kitout.toml" <<TOML
[[step]]
type = "absent"
id = "remove-fixture"
probe = "$dummy"
remove = ["rm", "-rf", "$dummy"]
TOML
  run kitout apply -y -m "$WORK/kitout.toml"
  [ "$status" -eq 0 ]
  [ ! -e "$dummy" ]                       # removed
  # idempotent: absent now → satisfied, second apply is a no-op
  run kitout apply -y -m "$WORK/kitout.toml"
  [ "$status" -eq 0 ]
}
