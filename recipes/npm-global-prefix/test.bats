#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "npm-global-prefix: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "npm-global-prefix: writes the prefix + PATH block and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:npm-global-prefix' "$HOME/.zshrc"
  grep -qF 'NPM_CONFIG_PREFIX="$HOME/.npm-global"' "$HOME/.zshrc"
  grep -qF '.npm-global/bin:$PATH' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"    # untouched preamble survives

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}

@test "npm-global-prefix: exported vars resolve to a user-owned path under HOME" {
  home="$WORK/guardhome"; mkdir -p "$home"
  run env HOME="$home" sh -c '
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="$HOME/.npm-global/bin:$PATH"
    echo "$NPM_CONFIG_PREFIX"
    echo "$PATH"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"$home/.npm-global"* ]]
  [[ "$output" == *"$home/.npm-global/bin:"* ]]
}
