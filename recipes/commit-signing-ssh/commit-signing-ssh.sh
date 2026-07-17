#!/usr/bin/env bash
# Configure git to sign commits and tags with an SSH key (git 2.34+ / OpenSSH
# 8.2+). Sets gpg.format=ssh, user.signingkey to your PUBLIC key, turns on
# commit/tag signing, and builds an allowed_signers file so local verification
# (`git log --show-signature`) works.
#
# EDIT THESE TWO before adopting:
#   SIGNING_KEY — path to your PUBLIC key (e.g. ~/.ssh/id_ed25519.pub)
#   SIGNER_EMAIL — the email in your git identity / the key's principal
#
# Idempotent: every write is compared first, so a converged config is a fast
# no-op. The step's check mirrors the core condition (gpg.format=ssh + signing on).
set -euo pipefail

SIGNING_KEY="$HOME/.ssh/id_ed25519.pub"
SIGNER_EMAIL="$(git config --global --get user.email 2>/dev/null || true)"
ALLOWED_SIGNERS="$HOME/.config/git/allowed_signers"

if [ ! -f "$SIGNING_KEY" ]; then
  echo "Signing key not found: $SIGNING_KEY" >&2
  echo "Generate one (ssh-keygen -t ed25519) or edit SIGNING_KEY in this script." >&2
  exit 1
fi
if [ -z "$SIGNER_EMAIL" ]; then
  echo "No signer email: set user.email in git or edit SIGNER_EMAIL." >&2
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

# The public key line, as ssh-keygen prints it (type + base64 [+ comment]).
key_line="$(cat "$SIGNING_KEY")"

set_cfg gpg.format ssh
set_cfg user.signingkey "$SIGNING_KEY"
set_cfg commit.gpgsign true
set_cfg tag.gpgsign true
set_cfg gpg.ssh.allowedSignersFile "$ALLOWED_SIGNERS"

# allowed_signers maps an email to the key that may sign for it, so
# verification works offline. Append our entry only if it isn't present.
mkdir -p "$(dirname "$ALLOWED_SIGNERS")"
touch "$ALLOWED_SIGNERS"
entry="$SIGNER_EMAIL $key_line"
if ! grep -qxF "$entry" "$ALLOWED_SIGNERS"; then
  printf '%s\n' "$entry" >>"$ALLOWED_SIGNERS"
  echo "  added $SIGNER_EMAIL to allowed_signers"
fi

echo "SSH commit signing configured."
