#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "touchid-sudo: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "touchid-sudo: check probe distinguishes absent / active / commented" {
  # Pure probe logic against fixtures — no sudo, no real file touched (CI-safe).
  f="$WORK/sudo_local"
  run grep -q '^[^#]*pam_tid\.so' "$f"
  [ "$status" -ne 0 ]                                   # missing file → pending
  printf 'auth       sufficient     pam_tid.so\n' >"$f"
  run grep -q '^[^#]*pam_tid\.so' "$f"
  [ "$status" -eq 0 ]                                   # active line → satisfied
  printf '# auth sufficient pam_tid.so\n' >"$f"
  run grep -q '^[^#]*pam_tid\.so' "$f"
  [ "$status" -ne 0 ]                                   # commented → pending
}

@test "touchid-sudo: apply enables it and is idempotent (VM only)" {
  require_apply
  [ "$(sw_vers -productVersion | cut -d. -f1)" -ge 14 ] || skip "needs macOS 14+"
  run bash "$WORK/steps/touchid-sudo.sh"
  [ "$status" -eq 0 ]
  run grep -q '^[^#]*pam_tid\.so' /etc/pam.d/sudo_local
  [ "$status" -eq 0 ]
  # second run: already-enabled, still 0, no duplicate line
  run bash "$WORK/steps/touchid-sudo.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already enabled"* ]]
  [ "$(grep -c 'pam_tid\.so' /etc/pam.d/sudo_local)" -eq 1 ]
}
