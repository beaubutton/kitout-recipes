#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "shared-skills-dirs: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "shared-skills-dirs: check probe is pending before / satisfied after (isolated HOME)" {
  # Pure probe logic against an isolated HOME — no real home dir touched.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  probe='d="$HOME/.agents/skills"; [ -d "$d" ] || exit 1; for l in "$HOME/.claude/skills" "$HOME/.codex/skills"; do if [ -L "$l" ]; then [ "$(readlink "$l")" = "$d" ] || exit 1; else [ -e "$l" ] || exit 1; fi; done'

  run sh -c "$probe"
  [ "$status" -ne 0 ]                         # clean HOME → pending

  mkdir -p "$HOME/.agents/skills" "$HOME/.claude" "$HOME/.codex"
  ln -s "$HOME/.agents/skills" "$HOME/.claude/skills"
  ln -s "$HOME/.agents/skills" "$HOME/.codex/skills"
  run sh -c "$probe"
  [ "$status" -eq 0 ]                         # linked → satisfied
}

@test "shared-skills-dirs: apply links the dirs and is idempotent (isolated HOME)" {
  require_apply
  export HOME="$WORK/home"; mkdir -p "$HOME"

  run bash "$WORK/steps/shared-skills-dirs.sh"; [ "$status" -eq 0 ]
  [ -d "$HOME/.agents/skills" ]
  [ -L "$HOME/.claude/skills" ]
  [ "$(readlink "$HOME/.claude/skills")" = "$HOME/.agents/skills" ]
  [ -L "$HOME/.codex/skills" ]

  # Idempotent: second run is a clean no-op, exit 0.
  run bash "$WORK/steps/shared-skills-dirs.sh"; [ "$status" -eq 0 ]

  # Non-destructive: a pre-existing REAL dir is left untouched, not clobbered.
  rm "$HOME/.codex/skills"; mkdir -p "$HOME/.codex/skills"
  printf 'mine\n' >"$HOME/.codex/skills/keep.txt"
  run bash "$WORK/steps/shared-skills-dirs.sh"; [ "$status" -eq 0 ]
  [ ! -L "$HOME/.codex/skills" ]              # still a real dir
  [ -f "$HOME/.codex/skills/keep.txt" ]       # content preserved
}
