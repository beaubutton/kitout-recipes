#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() {
  # If the effect test ran maintenance start, undo the scheduler + registration.
  if [ -n "${REPO:-}" ] && [ -d "${REPO:-}/.git" ]; then
    git -C "$REPO" maintenance unregister >/dev/null 2>&1 || true
    git -C "$REPO" maintenance stop >/dev/null 2>&1 || true
  fi
  rm -rf "$WORK"
}

@test "git-maintenance: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "git-maintenance: check probe flips when the repo is registered (isolated HOME + fixture repo)" {
  # No `maintenance start` here — we set the global list by hand to exercise the
  # probe logic only. No launchd agent is installed.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  repo="$WORK/repo"; mkdir -p "$repo"; git -C "$repo" init -q
  top="$(git -C "$repo" rev-parse --show-toplevel)"
  probe="REPO='$repo'; top=\"\$(git -C \"\$REPO\" rev-parse --show-toplevel 2>/dev/null)\" || exit 1; git config --global --get-all maintenance.repo 2>/dev/null | grep -qxF \"\$top\""

  run sh -c "$probe"
  [ "$status" -ne 0 ]                                   # unregistered → pending
  git config --global --add maintenance.repo "$top"
  run sh -c "$probe"
  [ "$status" -eq 0 ]                                   # registered → satisfied
}

@test "git-maintenance: apply registers the repo and is idempotent (VM only — installs a scheduler)" {
  require_apply
  # Isolate HOME so we never touch the tester's real global config; use a
  # throwaway repo, not a real one. teardown unregisters + stops the scheduler.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  REPO="$WORK/repo"; export REPO
  mkdir -p "$REPO"; git -C "$REPO" init -q
  git -C "$REPO" -c user.email=t@e.x -c user.name=t commit -q --allow-empty -m init
  top="$(git -C "$REPO" rev-parse --show-toplevel)"

  run bash "$WORK/steps/git-maintenance.sh"
  [ "$status" -eq 0 ]
  git config --global --get-all maintenance.repo | grep -qxF "$top"

  # idempotent: second run reports already-enabled, doesn't double-register
  run bash "$WORK/steps/git-maintenance.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already enabled"* ]]
  [ "$(git config --global --get-all maintenance.repo | grep -cxF "$top")" -eq 1 ]
}
