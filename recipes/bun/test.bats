#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "bun: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "bun: probe convergence — present binary is satisfied, absent is pending (CI-safe)" {
  # Exercise the command-if-missing probe logic without installing anything.
  present_pending() {
    kitout plan -m "$1" --json | python3 -c 'import sys,json;print(json.load(sys.stdin)["pending"])'
  }

  cat >"$WORK/present.toml" <<'TOML'
[[step]]
type = "command-if-missing"
id = "probe-present"
probe = "sh"
install = ["false"]
TOML
  run present_pending "$WORK/present.toml"
  [ "$output" = "0" ]                     # `sh` exists → satisfied, installer never runs

  cat >"$WORK/absent.toml" <<'TOML'
[[step]]
type = "command-if-missing"
id = "probe-absent"
probe = "kitout-no-such-binary-xyz"
install = ["false"]
TOML
  run present_pending "$WORK/absent.toml"
  [ "$output" = "1" ]                     # missing → pending
}

@test "bun: apply installs bun and is idempotent (VM only)" {
  require_apply
  command -v brew >/dev/null || skip "brew not on PATH"
  command -v bun >/dev/null && skip "bun already installed — refusing to re-test on a real machine"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  command -v bun >/dev/null

  # idempotent: present now → nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(json.load(sys.stdin)[\"pending\"])'"
  [ "$output" = "0" ]
}
