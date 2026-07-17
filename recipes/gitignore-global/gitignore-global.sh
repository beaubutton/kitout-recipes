#!/usr/bin/env bash
# Install a curated global gitignore at ~/.config/git/ignore and point
# core.excludesfile at it. Covers OS cruft (.DS_Store), editor/IDE dirs, and
# common local-only files that should never be per-repo .gitignore entries.
#
# Idempotent: rewrites the file only when its content differs, and sets
# core.excludesfile only when it isn't already pointing here. The check probe
# mirrors both conditions.
#
# NOTE: git already reads ~/.config/git/ignore by default (its XDG fallback for
# core.excludesfile), but we set the key explicitly so behavior is deterministic
# even if you've set core.excludesfile elsewhere or exported an unusual
# XDG_CONFIG_HOME. Edit IGNORE_FILE / the heredoc to taste.
set -euo pipefail

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
IGNORE_FILE="$config_home/git/ignore"

# The curated body. Keep this in one place so the write and the compare agree.
read -r -d '' BODY <<'IGNORE' || true
# Managed by kitout (gitignore-global recipe). Global ignores — things that
# should never live in a repo's own .gitignore because they're about YOUR
# machine/tools, not the project.

# macOS
.DS_Store
.AppleDouble
.LSOverride
._*
.Spotlight-V100
.Trashes

# Editors / IDEs
.idea/
.vscode/
*.swp
*.swo
*~
.\#*
\#*\#

# Direnv / local env
.envrc.local
.env.local

# Local scratch & logs
*.log
.local/
.cache/

# Language / tool caches often left in trees
__pycache__/
.mypy_cache/
.pytest_cache/
.ruff_cache/
node_modules/
IGNORE

want="$BODY"

# Converged? File matches the curated body AND core.excludesfile points here.
# (The script always writes the fully-expanded path, so an exact compare is
# correct — a stale ~-relative value counts as not-yet-converged and re-writes.)
current_cfg="$(git config --global --get core.excludesfile 2>/dev/null || true)"
if [ -f "$IGNORE_FILE" ] \
  && [ "$(cat "$IGNORE_FILE")" = "$want" ] \
  && [ "$current_cfg" = "$IGNORE_FILE" ]; then
  echo "Global gitignore already installed at $IGNORE_FILE."
  exit 0
fi

mkdir -p "$(dirname "$IGNORE_FILE")"
printf '%s\n' "$want" >"$IGNORE_FILE"
git config --global core.excludesfile "$IGNORE_FILE"
echo "Installed global gitignore at $IGNORE_FILE and set core.excludesfile."
