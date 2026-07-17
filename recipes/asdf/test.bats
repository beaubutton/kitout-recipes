#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "asdf: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "asdf: writes the shim-PATH block and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:asdf' "$HOME/.zshrc"
  grep -qF 'ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"    # untouched preamble survives

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}

@test "asdf: PATH line prepends the shim dir, honoring ASDF_DATA_DIR override" {
  # Pure shell-logic check of the exact line shipped in the block, no asdf binary needed.
  run sh -c 'ASDF_DATA_DIR=/tmp/custom-asdf PATH=/usr/bin; export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"; echo "$PATH"'
  [ "$status" -eq 0 ]
  [[ "$output" == "/tmp/custom-asdf/shims:"* ]]

  run sh -c 'unset ASDF_DATA_DIR; HOME=/home/x; PATH=/usr/bin; export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"; echo "$PATH"'
  [ "$status" -eq 0 ]
  [[ "$output" == "/home/x/.asdf/shims:"* ]]
}
