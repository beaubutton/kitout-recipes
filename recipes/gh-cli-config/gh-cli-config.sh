#!/usr/bin/env bash
# Set sane GitHub CLI (`gh`) defaults:
#   editor       = $EDITOR (or vim)   — used for commit messages, issue/PR bodies, etc.
#   git_protocol = ssh                — clone/push over SSH instead of HTTPS
#   prompt       = enabled            — interactive prompts when a flag is omitted
#   alias "prs"  = pr list --author @me
#
# Idempotent: each `gh config set` is compared first, and the alias is only
# added if it doesn't already exist (gh itself refuses to clobber one).
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "gh not found on PATH — install it first (e.g. brew install gh)." >&2
  exit 1
fi

EDITOR_CMD="${EDITOR:-vim}"

set_cfg() {
  local key="$1" val="$2"
  if [ "$(gh config get "$key" 2>/dev/null)" = "$val" ]; then
    return 0
  fi
  gh config set "$key" "$val"
  echo "  set $key = $val"
}

set_cfg editor "$EDITOR_CMD"
set_cfg git_protocol ssh
set_cfg prompt enabled

if gh alias list 2>/dev/null | grep -q '^prs:'; then
  echo "  alias 'prs' already exists — left untouched"
else
  gh alias set prs "pr list --author @me"
  echo "  added alias prs = pr list --author @me"
fi

echo "gh CLI configured."
