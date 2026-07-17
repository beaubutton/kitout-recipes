#!/usr/bin/env bash
# Install tfenv — a Terraform version manager — into ~/.tfenv (or $TFENV_ROOT) by
# cloning the upstream repo, the method tfenv documents for non-Homebrew installs.
# tfenv is pure shell, so a git checkout IS the install; put ~/.tfenv/bin on PATH
# and `tfenv install <version>` pulls Terraform builds on demand.
# No sudo; everything stays under $HOME. Idempotent: a no-op once tfenv is present.
set -euo pipefail

tfenv_root="${TFENV_ROOT:-$HOME/.tfenv}"
if [ -x "$tfenv_root/bin/tfenv" ]; then
  echo "tfenv already installed at $tfenv_root."
  exit 0
fi

command -v git >/dev/null || { echo "git not on PATH — install it first." >&2; exit 1; }

# Shallow clone of the upstream repo's default-branch tip (unpinned — see README's
# Security note; add --branch <tag> to pin). tfenv itself is the checked-out shell.
git clone --depth 1 https://github.com/tfutils/tfenv.git "$tfenv_root"

echo "tfenv installed. Add \"$tfenv_root/bin\" to your PATH:"
echo "  export PATH=\"\${TFENV_ROOT:-\$HOME/.tfenv}/bin:\$PATH\""
echo "Then: tfenv install latest && tfenv use latest"
