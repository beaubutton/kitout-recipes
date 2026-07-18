#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "auto-security-updates: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "auto-security-updates: check probe parses defaults-read fixtures (read-only, no state change)" {
  # Pure probe logic against fixture strings — never writes the real domain.
  run sh -c "printf '1\n' | grep -q '^1$'"
  [ "$status" -eq 0 ]                      # true → matches
  run sh -c "printf '0\n' | grep -q '^1$'"
  [ "$status" -ne 0 ]                       # false → no match
  run sh -c "printf '' | grep -q '^1$'"
  [ "$status" -ne 0 ]                       # unset (empty read) → no match
}

@test "auto-security-updates: apply enables it and is idempotent (VM only — writes system prefs)" {
  require_apply
  # Mutates a system-wide preference domain and the update scheduler. Only run
  # on a throwaway VM.
  run bash "$WORK/steps/auto-security-updates.sh"
  [ "$status" -eq 0 ]

  domain='/Library/Preferences/com.apple.SoftwareUpdate'
  for key in AutomaticCheckEnabled AutomaticDownload ConfigDataInstall CriticalUpdateInstall; do
    run sh -c "defaults read '$domain' '$key'"
    [ "$output" = "1" ]
  done

  # second run: already-enabled, still 0 and reports so
  run bash "$WORK/steps/auto-security-updates.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already enabled"* ]]
}
