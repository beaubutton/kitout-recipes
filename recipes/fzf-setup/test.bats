#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "fzf-setup: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "fzf-setup: check probe tracks the managed marker (isolated HOME)" {
  export HOME="$WORK/home"; mkdir -p "$HOME"
  run sh -c 'grep -q "kitout:fzf" "$HOME/.zshrc" 2>/dev/null'
  [ "$status" -ne 0 ]                       # no rc / no marker → pending
  printf '# >>> kitout:fzf >>>\n# <<< kitout:fzf <<<\n' >"$HOME/.zshrc"
  run sh -c 'grep -q "kitout:fzf" "$HOME/.zshrc" 2>/dev/null'
  [ "$status" -eq 0 ]                       # marker present → satisfied
}

@test "fzf-setup: script no-ops when the block is already present (no fzf needed)" {
  # Already-wired → fast idempotent exit before we ever probe for fzf, so this
  # runs on a runner without fzf.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  printf '# mine\n# >>> kitout:fzf >>>\nx\n# <<< kitout:fzf <<<\n' >"$HOME/.zshrc"
  run bash "$WORK/steps/fzf-setup.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already wired"* ]]
}

@test "fzf-setup: apply wires the block once and is idempotent (needs fzf >=0.48, VM only)" {
  require_apply
  command -v fzf >/dev/null || skip "fzf not installed on this runner"
  fzf --zsh >/dev/null 2>&1 || skip "fzf too old for --zsh (needs >= 0.48)"
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run bash "$WORK/steps/fzf-setup.sh"
  [ "$status" -eq 0 ]
  grep -q 'kitout:fzf' "$HOME/.zshrc"
  grep -q 'fzf --zsh' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"                 # preamble survives

  # idempotent: second run is a no-op, marker not duplicated
  run bash "$WORK/steps/fzf-setup.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already wired"* ]]
  [ "$(grep -c '>>> kitout:fzf >>>' "$HOME/.zshrc")" -eq 1 ]
}

@test "fzf-setup: rc file without a trailing newline isn't mangled (needs fzf >=0.48, VM only)" {
  require_apply
  command -v fzf >/dev/null || skip "fzf not installed on this runner"
  fzf --zsh >/dev/null 2>&1 || skip "fzf too old for --zsh (needs >= 0.48)"
  export HOME="$WORK/home"; mkdir -p "$HOME"
  printf 'export FOO=bar' >"$HOME/.zshrc"            # NO trailing newline

  run bash "$WORK/steps/fzf-setup.sh"
  [ "$status" -eq 0 ]
  grep -q '^export FOO=bar$' "$HOME/.zshrc"          # user's last line intact
  grep -q '^# >>> kitout:fzf >>>$' "$HOME/.zshrc"    # begin marker starts clean, not glued
}
