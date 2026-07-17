#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "pyenv: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "pyenv: check probe distinguishes unset / system / 3.x (CI-safe, stubbed pyenv)" {
  # Pure check-logic test with a fake `pyenv` on PATH — no real pyenv, no compiling.
  bin="$WORK/bin"; mkdir -p "$bin"
  make_stub() { printf '#!/usr/bin/env bash\n[ "$1" = global ] && echo "%s"\n' "$1" >"$bin/pyenv"; chmod +x "$bin/pyenv"; }
  probe() { PATH="$bin:$PATH" sh -c "command -v pyenv >/dev/null 2>&1 && pyenv global 2>/dev/null | head -n1 | grep -q '^3\\.'"; }

  make_stub "system"; run probe; [ "$status" -ne 0 ]      # system → pending
  make_stub "3.12.4"; run probe; [ "$status" -eq 0 ]       # 3.x   → satisfied
  make_stub "2.7.18"; run probe; [ "$status" -ne 0 ]       # 2.x   → pending
}

@test "pyenv: script writes the hook block once and is idempotent (stubbed, isolated HOME)" {
  require_apply
  # Fake `pyenv` so the script runs end-to-end without compiling CPython. It reports
  # `system` (so the hook is written), then accepts install/global/latest as no-ops.
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"
  bin="$WORK/bin"; mkdir -p "$bin"
  cat >"$bin/pyenv" <<'STUB'
#!/usr/bin/env bash
case "$1" in
  global)  echo system ;;                 # never "converges" → exercises the write path
  latest)  echo 3.12.4 ;;
  install) exit 0 ;;
  *)       exit 0 ;;
esac
STUB
  chmod +x "$bin/pyenv"
  export PATH="$bin:$PATH"

  run bash "$BATS_TEST_DIRNAME/pyenv.sh"; [ "$status" -eq 0 ]
  grep -q '>>> recipes:pyenv' "$HOME/.zshrc"
  grep -q 'pyenv init - zsh' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"                      # preamble untouched

  run bash "$BATS_TEST_DIRNAME/pyenv.sh"; [ "$status" -eq 0 ]
  [ "$(grep -c '>>> recipes:pyenv' "$HOME/.zshrc")" -eq 1 ]  # no duplicate block
}
