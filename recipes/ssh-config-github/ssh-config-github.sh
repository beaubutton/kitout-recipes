#!/usr/bin/env bash
# Add a github.com Host block to ~/.ssh/config and pin GitHub's ed25519 host key in
# ~/.ssh/known_hosts. The host key is HARDCODED (from GitHub's published list) and
# VERIFIED against GitHub's published SHA256 fingerprint before being written — so
# a corrupted paste can't slip a wrong key into known_hosts.
# Idempotent: exits fast once both the config block and the known_hosts line exist.
set -euo pipefail

ssh_dir="${HOME}/.ssh"
config="${ssh_dir}/config"
known="${ssh_dir}/known_hosts"

# GitHub's published github.com ed25519 host key and its expected SHA256 fingerprint.
# Source: https://docs.github.com/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints
gh_hostkey='github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'
gh_fp_expected='SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU'

mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

# --- Host block in ~/.ssh/config -------------------------------------------------
begin='# >>> recipes:github >>>'
end='# <<< recipes:github <<<'
if [ -f "$config" ] && grep -qF "$begin" "$config"; then
  config_ok=1
else
  config_ok=0
fi

if [ "$config_ok" -eq 0 ]; then
  touch "$config"
  chmod 600 "$config"
  {
    printf '%s\n' "$begin"
    printf 'Host github.com\n'
    printf '  HostName github.com\n'
    printf '  User git\n'
    printf '  AddKeysToAgent yes\n'
    printf '  IdentitiesOnly yes\n'
    printf '  IdentityFile ~/.ssh/id_ed25519\n'
    printf '%s\n' "$end"
  } >>"$config"
  echo "Added github.com Host block to ${config}."
else
  echo "github.com Host block already present."
fi

# --- Pinned host key in ~/.ssh/known_hosts --------------------------------------
touch "$known"
chmod 600 "$known"

# Already pinned? (compare the key material, ignoring any hashed-host formatting)
gh_keymaterial="$(printf '%s' "$gh_hostkey" | awk '{print $2, $3}')"
if grep -qF "$gh_keymaterial" "$known"; then
  echo "GitHub host key already pinned in ${known}."
else
  # Verify the hardcoded key hashes to GitHub's published fingerprint BEFORE trusting it.
  actual_fp="$(printf '%s\n' "$gh_hostkey" | ssh-keygen -lf - | awk '{print $2}')"
  if [ "$actual_fp" != "$gh_fp_expected" ]; then
    echo "REFUSING to pin: computed fingerprint ${actual_fp} != expected ${gh_fp_expected}." >&2
    exit 1
  fi
  printf '%s\n' "$gh_hostkey" >>"$known"
  echo "Pinned GitHub's ed25519 host key (verified ${gh_fp_expected})."
fi

echo "Done. Test with: ssh -T git@github.com"
