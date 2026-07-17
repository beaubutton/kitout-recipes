#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "pipx: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "pipx: check probe is pending without the PATH line, satisfied with it (CI-safe)" {
  # Pure check-logic against an isolated HOME fixture — no pipx, no real rc touched.
  home="$WORK/home"; mkdir -p "$home"
  probe() { HOME="$home" sh -c 'grep -qF "$HOME/.local/bin" "$HOME/.zshrc" 2>/dev/null'; }

  run probe; [ "$status" -ne 0 ]                          # no ~/.zshrc → pending
  printf '# my zshrc\n' >"$home/.zshrc"
  run probe; [ "$status" -ne 0 ]                          # present but no bin dir → pending
  # pipx ensurepath writes the *resolved* bin dir; the check greps for that literal.
  printf 'export PATH="%s/.local/bin:$PATH"\n' "$home" >>"$home/.zshrc"
  run probe; [ "$status" -eq 0 ]                          # bin dir referenced → satisfied
}

@test "pipx: apply ensures PATH and is idempotent (isolated HOME, VM only)" {
  require_apply
  command -v pipx >/dev/null || skip "pipx not installed on this runner"
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  # --all-shells must land the line in ~/.zshrc even though pipx's parent here is
  # bash; a bare `pipx ensurepath` would only touch ~/.bashrc and this would fail.
  run bash "$WORK/steps/pipx.sh"; [ "$status" -eq 0 ]
  grep -qF "$HOME/.local/bin" "$HOME/.zshrc"

  # idempotent: second run takes the fast already-configured path, still exit 0.
  run bash "$WORK/steps/pipx.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already configured"* ]]
}
