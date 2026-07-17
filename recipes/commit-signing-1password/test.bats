#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "commit-signing-1password: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "commit-signing-1password: check probe flips with op-ssh-sign + commit.gpgsign" {
  # Pure probe logic in an isolated HOME. We set the git keys directly — we do
  # NOT invoke op-ssh-sign or the recipe script (GUI-gated, needs the app).
  export HOME="$WORK/home"; mkdir -p "$HOME"
  probe='git config --global --get gpg.ssh.program 2>/dev/null | grep -q op-ssh-sign && [ "$(git config --global --get commit.gpgsign 2>/dev/null)" = "true" ]'
  run sh -c "$probe"
  [ "$status" -ne 0 ]                                   # clean → pending
  git config --global gpg.ssh.program '/Applications/1Password.app/Contents/MacOS/op-ssh-sign'
  git config --global commit.gpgsign true
  run sh -c "$probe"
  [ "$status" -eq 0 ]                                   # wired → satisfied
}

# GUI-gated + needs the 1Password app: this can only be verified by hand on a
# real desktop. Gated behind RECIPE_APPLY and skipped unless op-ssh-sign exists.
# We still don't auto-approve signing — the tester confirms the prompt manually.
@test "commit-signing-1password: manual verify (VM/desktop with 1Password)" {
  require_apply
  op='/Applications/1Password.app/Contents/MacOS/op-ssh-sign'
  [ -x "$op" ] || skip "1Password op-ssh-sign not installed — manual-verify only"
  skip "manual: set SIGNING_KEY, run the step, then 'git commit -S' and approve the 1Password prompt; verify with 'git log --show-signature'"
}
