#!/usr/bin/env bash
# Configure git to sign commits and tags with a GPG key:
#   user.signingkey = KEYID
#   commit.gpgsign  = true
#   tag.gpgsign     = true
#   gpg.program     = the gpg binary on PATH
#
# EDIT KEYID below before adopting — find yours with:
#   gpg --list-secret-keys --keyid-format long
# (the ID is the part after "rsa4096/" or "ed25519/" on the "sec" line, e.g.
# a real key looks like ABCDEF0123456789, not this placeholder). If you don't
# have a key yet, generate one with `gpg --full-generate-key`.
#
# If KEYID is left as the placeholder, this fails loudly with instructions —
# the step sets on-error="warn" in step.toml, so a manifest apply continues
# past it instead of aborting the whole run.
# Idempotent: every write is compared first, so a converged config is a no-op.
set -euo pipefail

KEYID="REPLACE_WITH_YOUR_GPG_KEY_ID"

if [ "$KEYID" = "REPLACE_WITH_YOUR_GPG_KEY_ID" ]; then
  echo "commit-signing-gpg: KEYID is still the placeholder." >&2
  echo "  1. List your keys:   gpg --list-secret-keys --keyid-format long" >&2
  echo "  2. No key yet?       gpg --full-generate-key" >&2
  echo "  3. Edit KEYID in commit-signing-gpg.sh to the key ID, then re-run." >&2
  exit 1
fi

if ! command -v gpg >/dev/null 2>&1; then
  echo "gpg not found on PATH — install it first (e.g. brew install gnupg)." >&2
  exit 1
fi

if ! gpg --list-secret-keys "$KEYID" >/dev/null 2>&1; then
  echo "No secret key found for KEYID=$KEYID in your GPG keyring." >&2
  echo "Check 'gpg --list-secret-keys --keyid-format long' and fix KEYID." >&2
  exit 1
fi

set_cfg() {
  local key="$1" val="$2"
  if [ "$(git config --global --get "$key" 2>/dev/null)" = "$val" ]; then
    return 0
  fi
  git config --global "$key" "$val"
  echo "  set $key = $val"
}

set_cfg user.signingkey "$KEYID"
set_cfg commit.gpgsign true
set_cfg tag.gpgsign true
set_cfg gpg.program "$(command -v gpg)"

echo "GPG commit signing configured (key: $KEYID)."
