#!/usr/bin/env bash
# Set a personal global git identity, then add a conditional include so any
# repo under ~/work/ picks up a separate work identity instead:
#   git config --global user.name/user.email      — personal identity (global default)
#   ~/.gitconfig-work                              — [user] name/email for work repos
#   includeIf "gitdir:~/work/".path                — switches identity by directory
#
# EDIT the placeholders below before adopting: your personal name/email and
# your work name/email. If your work repos don't live under ~/work, change
# WORK_DIR here AND the "~/work/" gitdir pattern below (and in step.toml's
# check) to match — they must agree, or the check will never be satisfied.
# Idempotent: every write is compared first; ~/.gitconfig-work is only
# written if it doesn't already exist (never overwrites a real identity).
set -euo pipefail

PERSONAL_NAME="Your Name"
PERSONAL_EMAIL="you@example.com"
WORK_NAME="Your Name"
WORK_EMAIL="you@work-example.com"
WORK_DIR="$HOME/work"
WORK_GITCONFIG="$HOME/.gitconfig-work"

set_cfg() {
  local key="$1" val="$2"
  if [ "$(git config --global --get "$key" 2>/dev/null)" = "$val" ]; then
    return 0
  fi
  git config --global "$key" "$val"
  echo "  set $key = $val"
}

set_cfg user.name "$PERSONAL_NAME"
set_cfg user.email "$PERSONAL_EMAIL"

if [ ! -f "$WORK_GITCONFIG" ]; then
  cat >"$WORK_GITCONFIG" <<EOF
[user]
	name = $WORK_NAME
	email = $WORK_EMAIL
EOF
  echo "  wrote $WORK_GITCONFIG"
else
  echo "  $WORK_GITCONFIG already exists — left untouched"
fi

# includeIf's gitdir pattern must end in "/" to match a directory tree, and
# git expects a literal "~/" prefix (it expands it itself, not the shell) —
# these are intentionally single-quoted literals, not unexpanded paths.
include_key='includeIf.gitdir:~/work/.path'
# shellcheck disable=SC2088
include_val='~/.gitconfig-work'
if [ "$(git config --global --get "$include_key" 2>/dev/null)" = "$include_val" ]; then
  echo "Conditional work identity already configured."
  exit 0
fi
git config --global "$include_key" "$include_val"
echo "  set $include_key = $include_val"

mkdir -p "$WORK_DIR"

echo "Git identity configured: personal by default, work identity under ${WORK_DIR}/."
