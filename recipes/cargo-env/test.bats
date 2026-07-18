#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "cargo-env: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "cargo-env: writes the guarded source line and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:cargo-env' "$HOME/.zshrc"
  grep -qF '.cargo/env' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"    # untouched preamble survives

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}

@test "cargo-env: guard is safe to source when ~/.cargo/env doesn't exist" {
  home="$WORK/guardhome"; mkdir -p "$home"
  run env HOME="$home" sh -c '
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    echo ok
  '
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}

@test "cargo-env: guard sources ~/.cargo/env when present" {
  home="$WORK/carguhome"; mkdir -p "$home/.cargo"
  printf 'export CARGO_ENV_LOADED=1\n' >"$home/.cargo/env"
  run env HOME="$home" sh -c '
    [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    echo "$CARGO_ENV_LOADED"
  '
  [ "$status" -eq 0 ]
  [ "$output" = "1" ]
}
