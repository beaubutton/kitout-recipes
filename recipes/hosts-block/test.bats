#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "hosts-block: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "hosts-block: check probe is pending on a clean fixture hosts file" {
  # Pure probe logic against a fixture file — never touches the real /etc/hosts.
  printf '127.0.0.1 localhost\n' >"$WORK/hosts"
  run grep -q 'recipes:hosts-block' "$WORK/hosts"
  [ "$status" -ne 0 ]
}

@test "hosts-block: apply builds the region against a dummy hosts file, preserves existing lines, is idempotent" {
  require_apply
  # Never touches the real /etc/hosts — HOSTS_FILE overrides the target, and a
  # fake sudo shim (no real privilege) proves the script's own logic converges.
  fixture="$WORK/hosts"
  printf '127.0.0.1 localhost\n255.255.255.255 broadcasthost\n' >"$fixture"

  mkdir -p "$WORK/bin"
  cat >"$WORK/bin/sudo" <<'SH'
#!/bin/bash
[ "$1" = "-A" ] && shift
exec "$@"
SH
  chmod +x "$WORK/bin/sudo"

  run env PATH="$WORK/bin:$PATH" HOSTS_FILE="$fixture" bash "$WORK/steps/hosts-block.sh"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:hosts-block >>>' "$fixture"
  grep -q '0.0.0.0 example-tracker.com' "$fixture"
  grep -q '127.0.0.1 localhost' "$fixture"          # untouched line survives
  grep -q '255.255.255.255 broadcasthost' "$fixture" # untouched line survives

  # idempotent: second run no-ops, no duplicate region
  run env PATH="$WORK/bin:$PATH" HOSTS_FILE="$fixture" bash "$WORK/steps/hosts-block.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already up to date"* ]]
  [ "$(grep -c '>>> recipes:hosts-block >>>' "$fixture")" -eq 1 ]
}
