#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "ssh-keepalive: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "ssh-keepalive: writes the Host * block after existing entries, is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
  printf 'Host example\n  User me\n  HostName example.com\n' >"$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:ssh-keepalive' "$HOME/.ssh/config"
  grep -q 'Host \*' "$HOME/.ssh/config"
  grep -q 'ServerAliveInterval 60' "$HOME/.ssh/config"
  grep -q 'ServerAliveCountMax 3' "$HOME/.ssh/config"
  grep -q 'TCPKeepAlive yes' "$HOME/.ssh/config"
  grep -q 'Host example' "$HOME/.ssh/config"    # pre-existing block survives

  # the managed Host * block must come AFTER the pre-existing specific block
  # (first-match-wins means * has to be last, or it'd shadow "Host example")
  host_line="$(grep -n '^Host example$' "$HOME/.ssh/config" | head -1 | cut -d: -f1)"
  star_line="$(grep -n '^Host \*$' "$HOME/.ssh/config" | head -1 | cut -d: -f1)"
  [ "$star_line" -gt "$host_line" ]

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json 2>/dev/null | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
