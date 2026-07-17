#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "lockscreen-immediate: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "lockscreen-immediate: check probe expression parses against sample status text" {
  # We can't safely flip the runner's real screen-lock setting, so exercise the
  # grep the `check` uses against representative `sysadminctl -screenLock status`
  # strings — no state is read or changed on the machine (CI-safe).
  probe() { printf '%s' "$1" | grep -Eqi 'immediate|delay is 0([^0-9]|$)'; }

  run probe "screenLock delay is immediate (0 seconds)"
  [ "$status" -eq 0 ]                                   # immediate → satisfied
  run probe "screenLock delay is 0 seconds"
  [ "$status" -eq 0 ]                                   # 0 seconds → satisfied
  run probe "screenLock is off"
  [ "$status" -ne 0 ]                                   # off → pending
  run probe "screenLock delay is 300 seconds"
  [ "$status" -ne 0 ]                                   # grace period → pending
}

@test "lockscreen-immediate: apply sets immediate lock — MANUAL VERIFY (auth-gated)" {
  require_apply
  # This step PROMPTS for your login password and changes a real per-user security
  # setting on THIS machine (no isolated fixture exists for it). Do not run it in
  # CI or on a machine whose lock policy you care about. To verify by hand on a
  # throwaway VM:
  #   1) sysadminctl -screenLock status            # note current delay
  #   2) kitout apply -m <this manifest>           # answer the password prompt
  #   3) sysadminctl -screenLock status            # expect: immediate
  #   4) kitout plan -m <this manifest>            # expect: nothing pending (idempotent)
  #   5) sysadminctl -screenLock off               # restore if desired
  skip "manual verify only — auth-gated, mutates a real system security setting (see steps in comment)"
}
