#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "restic-scaffold: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "restic-scaffold: step.toml never contains a plaintext RESTIC_PASSWORD (read-only)" {
  ! grep -qE '^\s*export\s+RESTIC_PASSWORD=' "$BATS_TEST_DIRNAME/step.toml"
  grep -q 'RESTIC_PASSWORD_COMMAND' "$BATS_TEST_DIRNAME/step.toml"
}

@test "restic-scaffold: writes the env block and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:restic-scaffold' "$HOME/.zshrc"
  grep -q 'RESTIC_REPOSITORY' "$HOME/.zshrc"
  grep -q 'RESTIC_PASSWORD_COMMAND' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"    # untouched preamble survives

  # No plaintext password ever lands in the file.
  ! grep -qE '^\s*export\s+RESTIC_PASSWORD=' "$HOME/.zshrc"

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json 2>/dev/null | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
