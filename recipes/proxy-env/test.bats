#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "proxy-env: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "proxy-env: writes the block with commented proxy lines + active no_proxy, is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:proxy-env' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"                          # untouched preamble survives
  grep -q '^export no_proxy="localhost,127.0.0.1,::1,\*.local"$' "$HOME/.zshrc"
  grep -q '^export NO_PROXY="\$no_proxy"$' "$HOME/.zshrc"
  grep -q '^# export http_proxy=' "$HOME/.zshrc"                # placeholder is commented out
  grep -q '^# export https_proxy=' "$HOME/.zshrc"
  grep -q '^# export all_proxy=' "$HOME/.zshrc"

  # sourcing the managed block in a real shell sets no_proxy but NOT http_proxy
  # shellcheck disable=SC1091
  out="$(zsh -c "source '$HOME/.zshrc'; echo \"\$no_proxy|\${http_proxy:-unset}\"")"
  [ "$out" = "localhost,127.0.0.1,::1,*.local|unset" ]

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json 2>/dev/null | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
