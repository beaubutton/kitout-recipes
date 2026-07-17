#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "codex-statusline: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "codex-statusline: seed-merges status_line, preserves config, idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME/.codex"
  # Pre-existing config with an unrelated key and NO tui.status_line.
  printf 'model = "gpt-5"\n\n[tui]\ntheme = "dark"\n' >"$HOME/.codex/config.toml"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  # status_line seeded, existing keys preserved.
  run python3 -c 'import tomllib,os;d=tomllib.load(open(os.environ["HOME"]+"/.codex/config.toml","rb"));print(d["tui"]["status_line"][0]);print(d["tui"]["theme"]);print(d["model"])'
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" = "model" ]]
  [[ "${lines[1]}" = "dark" ]]
  [[ "${lines[2]}" = "gpt-5" ]]

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]

  # seed does not clobber: a user-set status_line survives a re-apply.
  printf 'model = "gpt-5"\n\n[tui]\nstatus_line = ["model"]\n' >"$HOME/.codex/config.toml"
  run kitout apply -y -m "$MANIFEST"; [ "$status" -eq 0 ]
  run python3 -c 'import tomllib,os;d=tomllib.load(open(os.environ["HOME"]+"/.codex/config.toml","rb"));print(d["tui"]["status_line"])'
  [ "$output" = "['"'"'model'"'"']" ]
}
