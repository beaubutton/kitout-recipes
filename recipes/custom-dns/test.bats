#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "custom-dns: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "custom-dns: comparison logic matches when servers already equal DNS (read-only)" {
  # Pure string-comparison logic mirroring the script/check — no networksetup
  # call is made against the real machine's network service.
  DNS="1.1.1.1 1.0.0.1"
  current="$(printf '1.1.1.1\n1.0.0.1\n')"
  # shellcheck disable=SC2086
  desired="$(printf '%s\n' $DNS)"
  [ "$current" = "$desired" ]

  current_mismatch="$(printf '8.8.8.8\n8.8.4.4\n')"
  [ "$current_mismatch" != "$desired" ]
}

@test "custom-dns: script refuses an unknown network service without invoking sudo (read-only, no mutation)" {
  # Real networksetup call, but read-only: an unknown service name makes the
  # script exit before it ever reaches the privileged setdnsservers call.
  command -v networksetup >/dev/null || skip "networksetup not present"
  run env SERVICE="kitout-recipes-no-such-service" DNS="1.1.1.1 1.0.0.1" \
    bash "$WORK/steps/custom-dns.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "custom-dns: apply sets the resolvers on a real service and is idempotent (VM only — changes network config)" {
  require_apply
  command -v networksetup >/dev/null || skip "networksetup not present"
  service="$(networksetup -listallnetworkservices 2>/dev/null | sed -n '2p')"
  [ -n "$service" ] || skip "no network service available on this runner"

  run env SERVICE="$service" DNS="1.1.1.1 1.0.0.1" bash "$WORK/steps/custom-dns.sh"
  [ "$status" -eq 0 ]
  run networksetup -getdnsservers "$service"
  [[ "$output" == *"1.1.1.1"* ]]

  # idempotent: second run reports already-set
  run env SERVICE="$service" DNS="1.1.1.1 1.0.0.1" bash "$WORK/steps/custom-dns.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already set"* ]]

  # restore automatic DNS so the runner isn't left pinned
  networksetup -setdnsservers "$service" Empty || true
}
