#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "ssh-config-github: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "ssh-config-github: check probe is pending on a clean HOME" {
  # Pure probe logic against an isolated, empty ~/.ssh (CI-safe, no writes).
  export HOME="$WORK/home"; mkdir -p "$HOME/.ssh"
  run sh -c "grep -qF '# >>> recipes:github >>>' \"$HOME/.ssh/config\" 2>/dev/null && grep -qF 'AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' \"$HOME/.ssh/known_hosts\" 2>/dev/null"
  [ "$status" -ne 0 ]
}

@test "ssh-config-github: apply writes config + pinned key, verifies fp, is idempotent" {
  require_apply
  # Fully safe on an ephemeral runner: isolated HOME, no network, no privilege.
  export HOME="$WORK/home"; mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
  printf 'Host example\n  User me\n' >"$HOME/.ssh/config"

  run bash "$WORK/steps/ssh-config-github.sh"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:github' "$HOME/.ssh/config"
  grep -q 'Host github.com' "$HOME/.ssh/config"
  grep -q 'Host example' "$HOME/.ssh/config"                     # pre-existing survives
  grep -qF 'AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' "$HOME/.ssh/known_hosts"

  # The pinned line must actually hash to GitHub's published fingerprint.
  fp="$(grep 'ssh-ed25519' "$HOME/.ssh/known_hosts" | ssh-keygen -lf - | awk '{print $2}')"
  [ "$fp" = "SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU" ]

  # idempotent: second run no-ops, no duplicate lines
  run bash "$WORK/steps/ssh-config-github.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already present"* ]]
  [ "$(grep -c 'AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl' "$HOME/.ssh/known_hosts")" -eq 1 ]
  [ "$(grep -c '>>> recipes:github' "$HOME/.ssh/config")" -eq 1 ]
}
