#!/usr/bin/env bash
# Install Oh My Zsh unattended into ~/.oh-my-zsh.
#
# Runs the official installer with the flags that make it non-interactive and
# non-destructive: it does NOT change your login shell (--keep-zshrc leaves an
# existing ~/.zshrc alone; RUNZSH=no doesn't drop you into a subshell; CHSH=no
# doesn't touch your default shell). Idempotent: a no-op once ~/.oh-my-zsh exists.
set -euo pipefail

if [ -d "$HOME/.oh-my-zsh" ]; then
  echo "Oh My Zsh already installed."
  exit 0
fi

# The installer needs curl (present on macOS) and git.
command -v git >/dev/null 2>&1 || { echo "git is required but not on PATH." >&2; exit 1; }

# Fetch the official installer and run it unattended. Piping into a shell with
# these env vars is the documented unattended path; --keep-zshrc leaves any
# existing ~/.zshrc untouched (and, on a fresh box, writes NO ~/.zshrc at all —
# Oh My Zsh is installed but you must source it yourself; see the README).
#
# curl -fsSL fails closed on HTTP errors, but a failed download inside $(...)
# would still leave `sh -c ""` running empty and exiting 0 under `set -e`. So we
# assert the framework actually landed rather than trusting a silent success.
RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installer finished but ~/.oh-my-zsh is missing (download or install failed)." >&2
  exit 1
fi

echo "Oh My Zsh installed into ~/.oh-my-zsh (login shell and default shell unchanged)."
