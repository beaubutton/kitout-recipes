#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "volta: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "volta: writes the VOLTA_HOME + guarded PATH block and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"; printf '# my zshrc\n' >"$HOME/.zshrc"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:volta' "$HOME/.zshrc"
  grep -qF 'VOLTA_HOME="$HOME/.volta"' "$HOME/.zshrc"
  grep -qF ':$VOLTA_HOME/bin:' "$HOME/.zshrc"
  grep -q '# my zshrc' "$HOME/.zshrc"    # untouched preamble survives

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}

@test "volta: guard skips re-adding VOLTA_HOME/bin when already on PATH (no duplicate)" {
  home="$WORK/guardhome"; mkdir -p "$home/.volta/bin"
  run env HOME="$home" sh -c '
    export VOLTA_HOME="$HOME/.volta"
    export PATH="$VOLTA_HOME/bin:/usr/bin"
    case ":$PATH:" in
      *":$VOLTA_HOME/bin:"*) ;;
      *) export PATH="$VOLTA_HOME/bin:$PATH" ;;
    esac
    echo "$PATH"
  '
  [ "$status" -eq 0 ]
  count="$(printf '%s' "$output" | tr ':' '\n' | grep -c "\.volta/bin")"
  [ "$count" -eq 1 ]
}

@test "volta: guard adds VOLTA_HOME/bin when absent from PATH" {
  home="$WORK/guardhome2"; mkdir -p "$home/.volta/bin"
  run env HOME="$home" sh -c '
    export VOLTA_HOME="$HOME/.volta"
    export PATH="/usr/bin"
    case ":$PATH:" in
      *":$VOLTA_HOME/bin:"*) ;;
      *) export PATH="$VOLTA_HOME/bin:$PATH" ;;
    esac
    echo "$PATH"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == "$home/.volta/bin:"* ]]
}
