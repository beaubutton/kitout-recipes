#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "vscode-settings: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "vscode-settings: seed-merges all six keys without clobbering existing ones, idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"
  mkdir -p "$HOME/Library/Application Support/Code/User"
  SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
  # A pre-existing settings.json with an unrelated key AND one of the six keys
  # already set to a non-default value — seed must leave it alone.
  printf '{"editor.fontSize": 14, "editor.formatOnSave": false}\n' >"$SETTINGS"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]

  python3 - "$SETTINGS" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
# Pre-existing keys survive untouched.
assert d["editor.fontSize"] == 14
assert d["editor.formatOnSave"] is False, "seed must not clobber an existing key"
# Newly-seeded keys are present with the recipe's defaults.
assert d["files.trimTrailingWhitespace"] is True
assert d["files.insertFinalNewline"] is True
assert d["editor.rulers"] == [80, 100]
assert d["telemetry.telemetryLevel"] == "off"
assert d["workbench.editor.enablePreview"] is False
PY
  [ "$status" -eq 0 ]

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json 2>/dev/null | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
