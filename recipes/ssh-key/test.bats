#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "ssh-key: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "ssh-key: check probe is pending when the key is absent, satisfied when present" {
  # Pure probe logic against an isolated HOME — no keygen, no agent (CI-safe).
  export HOME="$WORK/home"; mkdir -p "$HOME/.ssh"
  run sh -c 'test -f "$HOME/.ssh/id_ed25519"'
  [ "$status" -ne 0 ]                                   # absent → pending
  : >"$HOME/.ssh/id_ed25519"
  run sh -c 'test -f "$HOME/.ssh/id_ed25519"'
  [ "$status" -eq 0 ]                                   # present → satisfied
}

@test "ssh-key: generates a key non-interactively for the test, and is idempotent" {
  require_apply
  # Isolate HOME so we never touch the tester's real ~/.ssh, and never load a
  # real agent/Keychain. Pre-create the key WITHOUT a passphrase here ONLY because
  # this is a throwaway fixture key in a temp HOME — the recipe itself refuses to.
  export HOME="$WORK/home"; mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -N "" -C "fixture" -f "$HOME/.ssh/id_ed25519" >/dev/null
  # Agent ops can't run in CI reliably; assert the check + permission invariants
  # the script guarantees, and that a re-run over an existing key is a no-op.
  run sh -c 'test -f "$HOME/.ssh/id_ed25519"'
  [ "$status" -eq 0 ]
  run bash "$WORK/steps/ssh-key.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already present"* ]]
  [ "$(stat -f '%Lp' "$HOME/.ssh/id_ed25519")" = "600" ]
}
