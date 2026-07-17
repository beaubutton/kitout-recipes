#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "commit-signing-ssh: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "commit-signing-ssh: check probe flips with gpg.format + commit.gpgsign" {
  # Pure probe logic in an isolated HOME — no key, no real git config touched.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  probe='[ "$(git config --global --get gpg.format 2>/dev/null)" = "ssh" ] && [ "$(git config --global --get commit.gpgsign 2>/dev/null)" = "true" ]'
  run sh -c "$probe"
  [ "$status" -ne 0 ]                                   # clean → pending
  git config --global gpg.format ssh
  git config --global commit.gpgsign true
  run sh -c "$probe"
  [ "$status" -eq 0 ]                                   # both set → satisfied
}

@test "commit-signing-ssh: apply configures signing and is idempotent (isolated HOME + fixture key)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME/.ssh"
  export XDG_CONFIG_HOME="$HOME/.config"
  # Throwaway key + identity — never the tester's real ~/.ssh.
  ssh-keygen -t ed25519 -N '' -C 'test@example.com' -f "$HOME/.ssh/id_ed25519" >/dev/null
  git config --global user.email 'test@example.com'

  run bash "$WORK/steps/commit-signing-ssh.sh"
  [ "$status" -eq 0 ]
  [ "$(git config --global --get gpg.format)" = "ssh" ]
  [ "$(git config --global --get commit.gpgsign)" = "true" ]
  [ "$(git config --global --get user.signingkey)" = "$HOME/.ssh/id_ed25519.pub" ]
  grep -q 'test@example.com' "$HOME/.config/git/allowed_signers"

  # idempotent: no per-key writes, allowed_signers not double-appended
  before="$(wc -l <"$HOME/.config/git/allowed_signers")"
  run bash "$WORK/steps/commit-signing-ssh.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"set gpg.format"* ]]
  [ "$(wc -l <"$HOME/.config/git/allowed_signers")" -eq "$before" ]
}
