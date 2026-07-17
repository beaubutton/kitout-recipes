#!/usr/bin/env bash
# Install the Tmux Plugin Manager (TPM) by cloning it into ~/.tmux/plugins/tpm.
#
# TPM is the standard way to declare tmux plugins in ~/.tmux.conf. This recipe
# only clones the manager; you still add the `set -g @plugin` lines and the
# `run '~/.tmux/plugins/tpm/tpm'` bootstrap to your ~/.tmux.conf, then press
# prefix + I inside tmux to fetch the plugins themselves. Idempotent: a no-op once
# the clone's entrypoint (~/.tmux/plugins/tpm/tpm) exists.
set -euo pipefail

dest="$HOME/.tmux/plugins/tpm"

if [ -f "$dest/tpm" ]; then
  echo "TPM already installed at $dest."
  exit 0
fi

command -v git >/dev/null 2>&1 || { echo "git is required but not on PATH." >&2; exit 1; }

# If an EMPTY dir exists (e.g. an interrupted earlier run left one), git clone
# would fail; rmdir removes it only when empty. A dir with any files in it — a
# real TPM checkout or anything else — makes rmdir fail, so we abort and leave it.
if [ -d "$dest" ] && [ ! -f "$dest/tpm" ]; then
  rmdir "$dest" 2>/dev/null || {
    echo "$dest exists but isn't a TPM checkout; leaving it alone." >&2
    exit 1
  }
fi

mkdir -p "$(dirname "$dest")"
git clone --depth 1 https://github.com/tmux-plugins/tpm "$dest"

echo "TPM installed at $dest."
echo "Next: add TPM lines to ~/.tmux.conf, reload, then press prefix + I to install plugins."
