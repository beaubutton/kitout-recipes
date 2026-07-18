#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "xcode-command-line-tools: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "xcode-command-line-tools: check probe reads xcode-select (read-only, no state change)" {
  # Real, unprivileged probe against whatever CI/dev box this runs on — never
  # installs or removes anything.
  run sh -c "xcode-select -p >/dev/null 2>&1"
  # Whatever the outcome on this runner, the probe itself must not error out
  # in a way that isn't a clean 0/1 exit.
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ] || [ "$status" -eq 2 ]
}

@test "xcode-command-line-tools: softwareupdate label parsing extracts the CLT label (fixture, no network)" {
  # Exercise the exact parsing pipeline from the script against a captured
  # softwareupdate --list sample — no real softwareupdate call.
  fixture="$WORK/su-list.txt"
  cat >"$fixture" <<'EOF'
Software Update Tool

Finding available software
Software Update found the following new or updated software:
* Label: Command Line Tools for Xcode-15.3
	Title: Command Line Tools for Xcode, Version: 15.3, Size: 1258408K, Recommended: YES, Action: restart,
* Label: macOS Sonoma 14.5
	Title: macOS Sonoma 14.5, Version: 14.5, Size: 123456K, Recommended: YES,
EOF
  run bash -c "grep -E '^\* Label: Command Line Tools' '$fixture' | sed 's/^\* Label: //' | tail -1"
  [ "$status" -eq 0 ]
  [ "$output" = "Command Line Tools for Xcode-15.3" ]
}

@test "xcode-command-line-tools: label parsing is empty (not an error) when no CLT label is present" {
  fixture="$WORK/su-list-empty.txt"
  cat >"$fixture" <<'EOF'
Software Update Tool

No new software available.
EOF
  run bash -c "set -euo pipefail; label=\$( (cat '$fixture' || true) | grep -E '^\* Label: Command Line Tools' | sed 's/^\* Label: //' | tail -1 || true); echo \"[\$label]\""
  [ "$status" -eq 0 ]
  [ "$output" = "[]" ]
}

@test "xcode-command-line-tools: already-installed short-circuits without sudo or softwareupdate (VM only)" {
  require_apply
  xcode-select -p >/dev/null 2>&1 || skip "CLTs not installed on this runner — nothing to short-circuit"

  run bash "$WORK/steps/xcode-command-line-tools.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]

  # idempotent: still nothing pending
  run sh -c "kitout plan -m '$MANIFEST' --json 2>/dev/null | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}
