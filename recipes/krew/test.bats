#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "krew: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "krew: check probe distinguishes absent / present (fixture, no network)" {
  # Pure probe logic — no download. Point KREW_ROOT at a throwaway dir.
  export KREW_ROOT="$WORK/krew"
  run sh -c 'test -x "${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew"'
  [ "$status" -ne 0 ]                       # nothing there → pending
  mkdir -p "$KREW_ROOT/bin"
  : >"$KREW_ROOT/bin/kubectl-krew"; chmod +x "$KREW_ROOT/bin/kubectl-krew"
  run sh -c 'test -x "${KREW_ROOT:-$HOME/.krew}/bin/kubectl-krew"'
  [ "$status" -eq 0 ]                        # present + executable → satisfied
}

@test "krew: apply installs krew and is idempotent (network, isolated root)" {
  require_apply
  command -v kubectl >/dev/null || skip "kubectl not installed on this runner"
  # Isolate HOME + KREW_ROOT so we never touch the tester's real ~/.krew.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  export KREW_ROOT="$WORK/krew"

  run bash "$WORK/steps/krew.sh"
  [ "$status" -eq 0 ]
  [ -x "$KREW_ROOT/bin/kubectl-krew" ]

  # Idempotent: second run sees it installed, still exit 0, no re-download.
  run bash "$WORK/steps/krew.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}
