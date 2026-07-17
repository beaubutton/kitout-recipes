#!/usr/bin/env bash
# Generate a personal ed25519 SSH key if one doesn't exist, then load it into the
# ssh-agent and store its passphrase in the login Keychain (macOS).
# Idempotent: once ~/.ssh/id_ed25519 exists this only (re-)adds it to the agent,
# which is itself a no-op if it's already loaded.
set -euo pipefail

key="${HOME}/.ssh/id_ed25519"
comment="${SSH_KEY_COMMENT:-$(whoami)@$(hostname -s)}"

if [ ! -f "$key" ]; then
  # ssh-keygen's passphrase prompt reads from stdin. If stdin is NOT a terminal
  # (piped, /dev/null, CI, a detached runner), the prompt returns an EMPTY string
  # and ssh-keygen silently writes an UNENCRYPTED key — the exact plaintext secret
  # this recipe exists to prevent. Refuse to generate unless we have a real TTY.
  if [ ! -t 0 ]; then
    echo "Refusing to generate ${key}: stdin is not a terminal, so the passphrase" >&2
    echo "prompt would be answered EMPTY and the key written unencrypted." >&2
    echo "Run 'kitout apply' from an interactive terminal (see the recipe's Security note)." >&2
    exit 1
  fi
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  echo "No ${key} found — generating an ed25519 key."
  echo "You will be asked for a PASSPHRASE. Choose a strong one; do NOT leave it empty."
  # No -N: ssh-keygen prompts interactively so YOU pick the passphrase. We never
  # bake in an empty passphrase — an unencrypted private key is a plaintext secret.
  ssh-keygen -t ed25519 -a 100 -C "$comment" -f "$key"
  # Defense in depth: even interactively, a user can just hit Enter twice. Verify
  # the key actually carries a passphrase; if not, destroy it and fail loudly
  # rather than leave an unencrypted identity on disk.
  if ssh-keygen -y -P "" -f "$key" >/dev/null 2>&1; then
    echo "Generated key has an EMPTY passphrase — removing it. Re-run and set one." >&2
    rm -f "$key" "${key}.pub"
    exit 1
  fi
else
  echo "SSH key ${key} already present."
fi

chmod 600 "$key"
[ -f "${key}.pub" ] && chmod 644 "${key}.pub"

# Load into the agent and persist the passphrase in the login Keychain so you're
# not re-prompted every session. --apple-use-keychain is a no-op on non-Apple
# ssh-add, so fall back to a plain add there. If no agent is reachable, say so and
# succeed anyway — the key on disk is the durable state; loading is a convenience.
if [ -z "${SSH_AUTH_SOCK:-}" ] && ! ssh-add -l >/dev/null 2>&1; then
  echo "No ssh-agent reachable — skipping agent load. Run 'ssh-add --apple-use-keychain \"$key\"' when one is running."
elif ssh-add -l 2>/dev/null | grep -q "$(ssh-keygen -lf "$key" | awk '{print $2}')"; then
  echo "Key already loaded in the agent."
elif ssh-add --apple-use-keychain "$key" 2>/dev/null; then
  echo "Key added to the agent and passphrase saved to the login Keychain."
else
  ssh-add "$key" || echo "Could not add key to the agent (no agent?) — skipping."
fi
