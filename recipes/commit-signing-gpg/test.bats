#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "commit-signing-gpg: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "commit-signing-gpg: check probe flips with commit.gpgsign (isolated HOME)" {
  # Pure probe logic in an isolated HOME — no key, no real git config touched.
  export HOME="$WORK/home"; mkdir -p "$HOME"
  probe='[ "$(git config --global --get commit.gpgsign 2>/dev/null)" = "true" ]'
  run sh -c "$probe"
  [ "$status" -ne 0 ]                                   # clean → pending
  git config --global commit.gpgsign true
  run sh -c "$probe"
  [ "$status" -eq 0 ]                                   # set → satisfied
}

@test "commit-signing-gpg: refuses to run with the placeholder KEYID (fail-loud, no state change)" {
  # Safe to run for real: the placeholder guard exits 1 before touching git
  # config or requiring gpg at all — no isolation needed, nothing is mutated.
  run bash "$WORK/steps/commit-signing-gpg.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"KEYID is still the placeholder"* ]]
}

@test "commit-signing-gpg: apply configures signing and is idempotent (isolated HOME + fixture key)" {
  require_apply
  command -v gpg >/dev/null || skip "gpg not on PATH"
  # gpg-agent's control socket is a Unix domain socket with a short path
  # limit (~104 bytes on macOS) — it can't live under a deep mktemp tree, so
  # GNUPGHOME (and HOME, so git config lands alongside it) use a short /tmp
  # path instead of $WORK.
  SHORT_HOME="$(mktemp -d /tmp/kitout-gpg-test.XXXXXX)"
  export HOME="$SHORT_HOME"
  mkdir -p "$HOME/.gnupg"; chmod 700 "$HOME/.gnupg"
  export GNUPGHOME="$HOME/.gnupg"

  # Throwaway unattended key — never the tester's real keyring.
  cat >"$WORK/keygen.batch" <<'EOF'
%no-protection
Key-Type: eddsa
Key-Curve: ed25519
Subkey-Type: eddsa
Subkey-Curve: ed25519
Name-Real: Test User
Name-Email: test@example.com
Expire-Date: 0
%commit
EOF
  gpg --batch --generate-key "$WORK/keygen.batch" >/dev/null 2>&1
  keyid="$(gpg --list-secret-keys --with-colons | awk -F: '/^sec/{print $5; exit}')"
  [ -n "$keyid" ] || skip "could not generate a test GPG key"

  # Mimic a user editing only the KEYID= assignment line (the guard's
  # comparison string must stay literal, or the placeholder check is moot).
  sed "s/^KEYID=\"REPLACE_WITH_YOUR_GPG_KEY_ID\"/KEYID=\"${keyid}\"/" \
    "$WORK/steps/commit-signing-gpg.sh" >"$WORK/steps/run.sh"

  run bash "$WORK/steps/run.sh"
  [ "$status" -eq 0 ]
  [ "$(git config --global --get user.signingkey)" = "$keyid" ]
  [ "$(git config --global --get commit.gpgsign)" = "true" ]
  [ "$(git config --global --get tag.gpgsign)" = "true" ]

  # idempotent: second run makes no further writes
  run bash "$WORK/steps/run.sh"
  [ "$status" -eq 0 ]
  [[ "$output" != *"set user.signingkey"* ]]
  [[ "$output" != *"set commit.gpgsign"* ]]

  gpgconf --kill gpg-agent 2>/dev/null || true
  rm -rf "$SHORT_HOME"
}
