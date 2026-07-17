#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "vscode-extensions: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "vscode-extensions: check probe reflects code CLI presence (read-only)" {
  # The step's check is `command -v code`; exercise the same probe logic
  # against a stubbed PATH without touching any real VS Code install.
  STUBDIR="$WORK/stub-bin"
  mkdir -p "$STUBDIR"
  cat >"$STUBDIR/code" <<'SH'
#!/usr/bin/env bash
exit 0
SH
  chmod +x "$STUBDIR/code"

  run env PATH="$STUBDIR:$PATH" sh -c "command -v code"
  [ "$status" -eq 0 ]

  mkdir -p "$WORK/empty-bin"
  run sh -c "PATH='$WORK/empty-bin' command -v code || echo NOTFOUND"
  [ "$status" -eq 0 ]
  [[ "$output" == *"NOTFOUND"* ]]
}

@test "vscode-extensions: install loop only calls install-extension for missing ones, idempotent (stubbed code)" {
  require_apply
  # Stub `code` so the script's real logic runs against a fake extension
  # store instead of a real VS Code install.
  STUBDIR="$WORK/stub-bin"
  mkdir -p "$STUBDIR"
  STATE="$WORK/installed.txt"
  printf 'editorconfig.editorconfig\n' >"$STATE"

  cat >"$STUBDIR/code" <<SH
#!/usr/bin/env bash
case "\$1" in
  --list-extensions) cat "$STATE" ;;
  --install-extension) echo "\$2" >> "$STATE" ;;
  *) exit 1 ;;
esac
SH
  chmod +x "$STUBDIR/code"

  run env PATH="$STUBDIR:$PATH" bash "$WORK/steps/vscode-extensions.sh"
  [ "$status" -eq 0 ]
  grep -qix "dbaeumer.vscode-eslint" "$STATE"
  grep -qix "esbenp.prettier-vscode" "$STATE"
  grep -qix "editorconfig.editorconfig" "$STATE"

  # idempotent: second run installs nothing new, reports already-satisfied
  run env PATH="$STUBDIR:$PATH" bash "$WORK/steps/vscode-extensions.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}
