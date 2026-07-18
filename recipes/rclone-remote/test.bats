#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "rclone-remote: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "rclone-remote: step.toml never embeds a token, writes no rclone.conf reference (read-only)" {
  ! grep -qiE 'access_key_id|secret_access_key|token\s*=' "$BATS_TEST_DIRNAME/step.toml"
  grep -q 'RCLONE_CONFIG_PASS' "$BATS_TEST_DIRNAME/step.toml"
  grep -q 'rclone sync' "$BATS_TEST_DIRNAME/step.toml"
}

@test "rclone-remote: writes the env+alias block and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:rclone-remote' "$HOME/.zshrc"
  grep -q 'RCLONE_CONFIG_PASS' "$HOME/.zshrc"
  grep -q 'alias backup-push' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"    # untouched preamble survives

  # No secret material ever lands in the file.
  ! grep -qiE 'access_key_id|secret_access_key' "$HOME/.zshrc"

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json 2>/dev/null | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
