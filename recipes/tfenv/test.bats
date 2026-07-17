#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "tfenv: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "tfenv: check probe distinguishes absent / present (fixture, no network)" {
  # Pure probe logic — no clone. Point TFENV_ROOT at a throwaway dir.
  export TFENV_ROOT="$WORK/tfenv"
  run sh -c 'test -x "${TFENV_ROOT:-$HOME/.tfenv}/bin/tfenv"'
  [ "$status" -ne 0 ]                       # nothing there → pending
  mkdir -p "$TFENV_ROOT/bin"
  : >"$TFENV_ROOT/bin/tfenv"; chmod +x "$TFENV_ROOT/bin/tfenv"
  run sh -c 'test -x "${TFENV_ROOT:-$HOME/.tfenv}/bin/tfenv"'
  [ "$status" -eq 0 ]                        # present + executable → satisfied
}

@test "tfenv: apply clones tfenv and is idempotent (network, isolated root)" {
  require_apply
  command -v git >/dev/null || skip "git not installed on this runner"
  # Isolate HOME + TFENV_ROOT so we never touch the tester's real ~/.tfenv.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  export TFENV_ROOT="$WORK/tfenv"

  run bash "$WORK/steps/tfenv.sh"
  [ "$status" -eq 0 ]
  [ -x "$TFENV_ROOT/bin/tfenv" ]

  # Idempotent: second run sees it installed, still exit 0, no re-clone.
  run bash "$WORK/steps/tfenv.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}
