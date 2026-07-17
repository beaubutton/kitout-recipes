#!/usr/bin/env bash
# Configure git to sign commits/tags with an SSH key held in 1Password, using
# the 1Password SSH agent + its op-ssh-sign helper. The PRIVATE key never leaves
# 1Password; git signs by calling op-ssh-sign, which prompts 1Password to sign.
#
# EDIT THIS before adopting:
#   SIGNING_KEY — your PUBLIC key string, exactly as 1Password shows it, e.g.
#     "ssh-ed25519 AAAAC3Nz... you@example.com"
#   (In 1Password: the SSH key item → "Configure" → copy the public key, or use
#    the git-signing snippet 1Password offers.)
#
# Idempotent: every write is compared first; a converged config is a no-op. The
# step's check mirrors the core condition (op-ssh-sign wired in + signing on).
set -euo pipefail

# Your PUBLIC key string. Leave the placeholder and the script will refuse to run
# until you paste your real key.
SIGNING_KEY="ssh-ed25519 REPLACE_WITH_YOUR_PUBLIC_KEY you@example.com"

# 1Password's SSH signing helper, shipped inside the app bundle. This is the
# exact path 1Password itself writes into ~/.gitconfig.
OP_SSH_SIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"

case "$SIGNING_KEY" in
  *REPLACE_WITH_YOUR_PUBLIC_KEY*)
    echo "Set SIGNING_KEY to your 1Password public key before running." >&2
    exit 1
    ;;
esac
if [ ! -x "$OP_SSH_SIGN" ]; then
  echo "op-ssh-sign not found at $OP_SSH_SIGN — install 1Password 8 and enable" >&2
  echo "the SSH agent (Settings → Developer → Use the SSH agent)." >&2
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

set_cfg gpg.format ssh
# A literal public key rather than a file path: git wants the raw key string
# here (1Password holds the private half; there's no .pub on disk to point at).
set_cfg user.signingkey "$SIGNING_KEY"
set_cfg gpg.ssh.program "$OP_SSH_SIGN"
set_cfg commit.gpgsign true
set_cfg tag.gpgsign true

echo "1Password SSH commit signing configured."
