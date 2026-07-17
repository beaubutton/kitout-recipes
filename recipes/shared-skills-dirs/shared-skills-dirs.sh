#!/usr/bin/env bash
# Create one shared home for agent "skills" and point each agent's skills dir at
# it, so a skill you drop once is visible to every coding agent. The neutral
# ~/.agents/skills is the source of truth; ~/.claude/skills and ~/.codex/skills
# become symlinks to it. Idempotent: a no-op once the tree is in place.
#
# NON-DESTRUCTIVE: if an agent's skills path already exists as a real directory
# (not our symlink), we LEAVE IT ALONE and just warn — we never move or delete a
# directory you already populated. Adopt it by hand if you want it shared.
set -euo pipefail

neutral="$HOME/.agents/skills"
# Per-agent skills dirs to link at the neutral one. Edit to taste.
links=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
)

mkdir -p "$neutral"

for link in "${links[@]}"; do
  if [ -L "$link" ]; then
    # Already a symlink — retarget only if it points somewhere else.
    if [ "$(readlink "$link")" = "$neutral" ]; then
      continue
    fi
    ln -sfn "$neutral" "$link"
    echo "Repointed $link -> $neutral"
  elif [ -e "$link" ]; then
    # A real file/dir is already there — do not touch it.
    echo "Left existing $link untouched (not a symlink); skipping."
  else
    mkdir -p "$(dirname "$link")"
    ln -s "$neutral" "$link"
    echo "Linked $link -> $neutral"
  fi
done

echo "Shared skills dir ready at $neutral"
