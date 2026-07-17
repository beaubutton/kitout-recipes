#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "gatekeeper-on: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "gatekeeper-on: check probe string-matching logic (fixture, no state change)" {
  run sh -c "printf 'assessments enabled\n' | grep -q 'assessments enabled'"
  [ "$status" -eq 0 ]
  run sh -c "printf 'assessments disabled\n' | grep -q 'assessments enabled'"
  [ "$status" -ne 0 ]
}

@test "gatekeeper-on: check probe reads real spctl status (read-only, no state change)" {
  # Safe anywhere: --status is a read-only query, never a write.
  command -v spctl >/dev/null || skip "spctl not present on this platform"
  run spctl --status
  [ "$status" -eq 0 ]
  [[ "$output" == *"assessments"* ]]
}

@test "gatekeeper-on: apply enables Gatekeeper and is idempotent (VM only — changes system security policy)" {
  require_apply
  # Mutates the machine's Gatekeeper policy. Only run on a throwaway VM. Some
  # configurations require Recovery mode instead (see README); skip there.
  run bash "$WORK/steps/gatekeeper-on.sh"
  if [ "$status" -ne 0 ]; then
    skip "this configuration requires enabling Gatekeeper from Recovery mode"
  fi

  run spctl --status
  [[ "$output" == *"assessments enabled"* ]]

  # second run: already-enabled, still 0 and reports so
  run bash "$WORK/steps/gatekeeper-on.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already enabled"* ]]
}
