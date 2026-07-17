#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "claude-statusline: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "claude-statusline: the jq command renders the status line from session JSON" {
  command -v jq >/dev/null || skip "jq not installed on this runner"
  # Pull the exact command out of step.toml and feed it Claude's documented input.
  cmd="$(python3 -c 'import tomllib;print(tomllib.load(open("'"$BATS_TEST_DIRNAME"'/step.toml","rb"))["step"][0]["value"]["statusLine"]["command"])')"
  input='{"model":{"display_name":"Opus"},"context_window":{"used_percentage":8.7},"workspace":{"current_dir":"/a/b/kitout"}}'
  run sh -c "printf '%s' '$input' | $cmd"
  [ "$status" -eq 0 ]
  [ "$output" = "[Opus] 8% ctx · kitout" ]
}

@test "claude-statusline: the jq command degrades gracefully on missing fields (never errors the bar)" {
  command -v jq >/dev/null || skip "jq not installed on this runner"
  cmd="$(python3 -c 'import tomllib;print(tomllib.load(open("'"$BATS_TEST_DIRNAME"'/step.toml","rb"))["step"][0]["value"]["statusLine"]["command"])')"
  # Every field absent/null must still exit 0 (blank parts, not a blank bar).
  for input in '{}' \
    '{"model":{"display_name":"Opus"},"context_window":{"used_percentage":8}}' \
    '{"context_window":{"used_percentage":null},"workspace":{"current_dir":"/a/b/kitout"}}'; do
    run sh -c "printf '%s' '$input' | $cmd"
    [ "$status" -eq 0 ]
  done
}

@test "claude-statusline: seed-merges the key, doesn't clobber, idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME/.claude"
  # A pre-existing settings.json with other keys and NO statusLine.
  printf '{"theme":"dark"}\n' >"$HOME/.claude/settings.json"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  # statusLine seeded, existing key preserved.
  [ "$(python3 -c 'import json;print(json.load(open("'"$HOME"'/.claude/settings.json"))["statusLine"]["type"])')" = "command" ]
  [ "$(python3 -c 'import json;print(json.load(open("'"$HOME"'/.claude/settings.json"))["theme"])')" = "dark" ]

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]

  # seed does not clobber: a user-set statusLine survives a re-apply.
  python3 -c 'import json,os;p=os.environ["HOME"]+"/.claude/settings.json";d=json.load(open(p));d["statusLine"]={"type":"command","command":"echo mine"};json.dump(d,open(p,"w"))'
  run kitout apply -y -m "$MANIFEST"; [ "$status" -eq 0 ]
  [ "$(python3 -c 'import json;print(json.load(open("'"$HOME"'/.claude/settings.json"))["statusLine"]["command"])')" = "echo mine" ]
}
