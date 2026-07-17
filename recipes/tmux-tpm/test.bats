#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "tmux-tpm: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "tmux-tpm: check probe tracks the clone entrypoint (isolated HOME)" {
  export HOME="$WORK/home"; mkdir -p "$HOME"
  run sh -c '[ -f "$HOME/.tmux/plugins/tpm/tpm" ]'
  [ "$status" -ne 0 ]                       # not cloned → pending
  mkdir -p "$HOME/.tmux/plugins/tpm"; : >"$HOME/.tmux/plugins/tpm/tpm"
  run sh -c '[ -f "$HOME/.tmux/plugins/tpm/tpm" ]'
  [ "$status" -eq 0 ]                       # entrypoint present → satisfied
}

@test "tmux-tpm: script no-ops when already installed (isolated HOME, no network)" {
  # Pre-create the entrypoint so the script takes its fast idempotent exit
  # WITHOUT cloning over the network.
  export HOME="$WORK/home"; mkdir -p "$HOME/.tmux/plugins/tpm"; : >"$HOME/.tmux/plugins/tpm/tpm"
  run bash "$WORK/steps/tmux-tpm.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}

@test "tmux-tpm: apply clones TPM and is idempotent (network, VM only)" {
  require_apply
  command -v git >/dev/null || skip "git not installed on this runner"
  export HOME="$WORK/home"; mkdir -p "$HOME"
  run bash "$WORK/steps/tmux-tpm.sh"
  [ "$status" -eq 0 ]
  [ -f "$HOME/.tmux/plugins/tpm/tpm" ]
  # second run: already-installed fast path, still 0
  run bash "$WORK/steps/tmux-tpm.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}
