#!/usr/bin/env bash
# Ensure pipx's app bin dir (~/.local/bin) is on PATH by running
# `pipx ensurepath --all-shells`, which appends the export to your shell rc
# files — including ~/.zshrc.
#
# Why --all-shells: pipx (via the userpath lib) picks which rc file to edit by
# sniffing its PARENT process name. Run non-interactively from a script the
# parent is *bash*, so a bare `pipx ensurepath` writes ~/.bashrc / ~/.bash_profile
# and NEVER ~/.zshrc — leaving a zsh workstation un-fixed and this step's zsh
# check permanently pending. --all-shells writes every shell's rc (zsh included),
# so the ~/.zshrc check converges and a new zsh shell actually sees the bin dir.
#
# Idempotent: userpath skips a rc file that already contains the line, and we
# exit 0 fast when ~/.local/bin is already referenced in ~/.zshrc. Assumes the
# `pipx` binary is already on PATH.
set -euo pipefail

if ! command -v pipx >/dev/null 2>&1; then
  echo "pipx not found on PATH — install it first (brew install pipx)." >&2
  exit 1
fi

# pipx's app bin dir; PIPX_BIN_DIR overrides the ~/.local/bin default.
# Note: pipx resolves this path (symlinks/canonicalization) before writing it,
# so a PIPX_BIN_DIR with symlinked or relative components may not match this
# check verbatim — see the recipe's Caveats.
bin_dir="${PIPX_BIN_DIR:-$HOME/.local/bin}"
zshrc="$HOME/.zshrc"

# Fast, read-only convergence check: our rc already references the pipx bin dir.
if [ -f "$zshrc" ] && grep -qF "$bin_dir" "$zshrc"; then
  echo "pipx PATH already configured ($bin_dir referenced in $zshrc)."
  exit 0
fi

# --all-shells so ~/.zshrc is written regardless of the (bash) parent process.
# userpath dedups per rc file, so re-runs won't append a second line.
pipx ensurepath --all-shells
echo "pipx PATH ensured — open a new shell (or source your rc) to pick up $bin_dir."
