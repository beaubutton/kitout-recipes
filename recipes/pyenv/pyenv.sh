#!/usr/bin/env bash
# Set up pyenv (the Ruby-style Python version manager): install the shell hook into
# ~/.zshrc as a self-contained managed block, then install the latest stable CPython
# 3.x and make it the global default. Idempotent: exits 0 fast once a global 3.x is
# set. Assumes the `pyenv` binary is already on PATH (see the recipe's Requirements).
set -euo pipefail

if ! command -v pyenv >/dev/null 2>&1; then
  echo "pyenv not found on PATH — install it first (brew install pyenv)." >&2
  exit 1
fi

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"

# --- Convergence check: a global 3.x already selected? Then we're done. ----------
current_global="$(pyenv global 2>/dev/null | head -n1 || true)"
if [ -n "$current_global" ] && [ "$current_global" != "system" ] && \
   printf '%s\n' "$current_global" | grep -q '^3\.'; then
  echo "pyenv already set up (global Python $current_global)."
  exit 0
fi

# --- 1. Shell hook: managed block in ~/.zshrc (append once, never duplicate). -----
zshrc="$HOME/.zshrc"
begin='# >>> recipes:pyenv >>>'
end='# <<< recipes:pyenv <<<'
if [ ! -f "$zshrc" ] || ! grep -qF "$begin" "$zshrc"; then
  # These lines are written verbatim INTO ~/.zshrc — they must stay single-quoted so
  # $HOME/$PYENV_ROOT/$(...) expand in the user's future shells, not here at write time.
  # shellcheck disable=SC2016
  {
    printf '%s\n' "$begin"
    printf '%s\n' 'export PYENV_ROOT="$HOME/.pyenv"'
    printf '%s\n' '[ -d "$PYENV_ROOT/bin" ] && export PATH="$PYENV_ROOT/bin:$PATH"'
    printf '%s\n' 'eval "$(pyenv init - zsh)"'
    printf '%s\n' "$end"
  } >>"$zshrc"
  echo "Added pyenv shell hook to $zshrc."
fi

# --- 2. Install the latest stable CPython 3.x and set it global. ------------------
# `pyenv latest -k 3` resolves the newest *known* (installable) 3.x release.
target="$(pyenv latest -k 3 2>/dev/null || true)"
if [ -z "$target" ]; then
  echo "Could not resolve a latest 3.x (needs pyenv >= 2.3.0)." >&2
  echo "Install one manually, e.g.: pyenv install 3.12 && pyenv global 3.12" >&2
  exit 1
fi

echo "Installing Python $target (this compiles CPython and can take a few minutes)…"
pyenv install --skip-existing "$target"
pyenv global "$target"
echo "pyenv ready — global Python set to $target. Open a new shell to use it."
