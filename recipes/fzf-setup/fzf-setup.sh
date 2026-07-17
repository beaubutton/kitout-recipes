#!/usr/bin/env bash
# Enable fzf's zsh integration — key bindings (Ctrl-R history, Ctrl-T files,
# Alt-C cd) and fuzzy completion — by sourcing `fzf --zsh` from a managed block
# in ~/.zshrc.
#
# `fzf --zsh` (fzf >= 0.48) emits the key-bindings + completion script on stdout;
# sourcing it is the current, install-script-free way to wire fzf into zsh. We
# manage a marked block so re-runs are idempotent and removal is clean.
set -euo pipefail

rc="$HOME/.zshrc"
begin='# >>> kitout:fzf >>>'
end='# <<< kitout:fzf <<<'

if [ -f "$rc" ] && grep -q 'kitout:fzf' "$rc"; then
  echo "fzf shell integration already wired into ~/.zshrc."
  exit 0
fi

command -v fzf >/dev/null 2>&1 || { echo "fzf is required but not on PATH." >&2; exit 1; }

# Verify this fzf supports `--zsh` before we commit anything to the rc file.
if ! fzf --zsh >/dev/null 2>&1; then
  echo "This fzf is too old for 'fzf --zsh' (needs fzf >= 0.48)." >&2
  echo "Upgrade fzf (brew upgrade fzf), or run \$(brew --prefix)/opt/fzf/install." >&2
  exit 1
fi

# Append the managed block. We source `fzf --zsh` at shell-startup time (not the
# literal output) so it always matches the installed fzf version.
touch "$rc"

# If the rc file is non-empty and its last byte isn't a newline, our appended
# block would glue onto the user's last line (mangling their edit and the
# marker). Add a separating newline first so the block always starts clean.
if [ -s "$rc" ] && [ -n "$(tail -c1 "$rc")" ]; then
  printf '\n' >>"$rc"
fi

{
  printf '%s\n' "$begin"
  printf '%s\n' 'command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)'
  printf '%s\n' "$end"
} >>"$rc"

echo "Wired fzf key bindings + completion into ~/.zshrc — open a new shell to use them."
