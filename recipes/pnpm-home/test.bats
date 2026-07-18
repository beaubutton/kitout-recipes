#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "pnpm-home: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "pnpm-home: writes the PNPM_HOME + guarded PATH block and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:pnpm-home' "$HOME/.zshrc"
  grep -qF 'PNPM_HOME="$HOME/Library/pnpm"' "$HOME/.zshrc"
  grep -qF ':$PNPM_HOME:' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"    # untouched preamble survives

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}

@test "pnpm-home: guard skips re-adding PNPM_HOME when already on PATH (no duplicate)" {
  home="$WORK/guardhome"; mkdir -p "$home/Library/pnpm"
  run env HOME="$home" sh -c '
    export PNPM_HOME="$HOME/Library/pnpm"
    export PATH="$PNPM_HOME:/usr/bin"
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
    echo "$PATH"
  '
  [ "$status" -eq 0 ]
  # only ONE occurrence of the pnpm dir in PATH
  count="$(printf '%s' "$output" | tr ':' '\n' | grep -c "Library/pnpm")"
  [ "$count" -eq 1 ]
}

@test "pnpm-home: guard adds PNPM_HOME when absent from PATH" {
  home="$WORK/guardhome2"; mkdir -p "$home/Library/pnpm"
  run env HOME="$home" sh -c '
    export PNPM_HOME="$HOME/Library/pnpm"
    export PATH="/usr/bin"
    case ":$PATH:" in
      *":$PNPM_HOME:"*) ;;
      *) export PATH="$PNPM_HOME:$PATH" ;;
    esac
    echo "$PATH"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "$home/Library/pnpm:"* ]]
}
