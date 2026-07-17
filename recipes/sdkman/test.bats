#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "sdkman: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "sdkman: writes the guarded init block and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:sdkman' "$HOME/.zshrc"
  grep -q 'SDKMAN_DIR="\$HOME/.sdkman"' "$HOME/.zshrc"
  grep -q 'sdkman-init.sh' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"    # untouched preamble survives

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}

@test "sdkman: guard is safe to source when SDKMAN isn't installed (no such file)" {
  # Prove the [[ -s ... ]] guard no-ops cleanly when ~/.sdkman doesn't exist,
  # instead of erroring in every new shell before SDKMAN is installed.
  home="$WORK/guardhome"; mkdir -p "$home"
  run env HOME="$home" zsh -c '
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
    echo ok
  '
  [ "$status" -eq 0 ]
  [ "$output" = "ok" ]
}
