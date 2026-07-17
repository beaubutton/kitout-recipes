#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "1password-ssh-agent: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "1password-ssh-agent: writes the IdentityAgent block and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
  printf 'Host example\n  User me\n' >"$HOME/.ssh/config"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:1password-agent' "$HOME/.ssh/config"
  grep -q 'IdentityAgent' "$HOME/.ssh/config"
  grep -q 'com.1password/t/agent.sock' "$HOME/.ssh/config"
  grep -q 'Host example' "$HOME/.ssh/config"    # pre-existing entry survives

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
