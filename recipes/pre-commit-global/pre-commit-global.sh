#!/usr/bin/env bash
# Make every future `git init`/`git clone` install pre-commit's hooks
# automatically:
#   pre-commit init-templatedir ~/.config/git/template
#   git config --global init.templateDir ~/.config/git/template
#
# `pre-commit init-templatedir` drops a hook stub into that directory for
# every hook type pre-commit supports; git copies the template directory's
# contents into .git/ on every future init/clone once init.templateDir points
# at it. Each stub is a no-op unless the repo it lands in actually has a
# .pre-commit-config.yaml — pre-commit checks for that file at hook-run time.
#
# Requires the `pre-commit` tool on PATH (brew install pre-commit, or
# pipx install pre-commit). Idempotent.
set -euo pipefail

TEMPLATE_DIR="$HOME/.config/git/template"

if ! command -v pre-commit >/dev/null 2>&1; then
  echo "pre-commit not found on PATH — install it first (e.g. brew install pre-commit)." >&2
  exit 1
fi

already_templated=false
if [ "$(git config --global --get init.templateDir 2>/dev/null)" = "$TEMPLATE_DIR" ]; then
  already_templated=true
fi

# init-templatedir is itself idempotent (it (re)writes hook stubs into the
# directory), so just re-run it whenever the config isn't already pointed
# there — cheap, and keeps stubs current with the installed pre-commit version.
if [ "$already_templated" = false ]; then
  pre-commit init-templatedir "$TEMPLATE_DIR" >/dev/null
  git config --global init.templateDir "$TEMPLATE_DIR"
  echo "  set init.templateDir = $TEMPLATE_DIR"
  echo "pre-commit template dir configured. Future 'git init'/'git clone' will wire up hooks automatically."
else
  echo "pre-commit template dir already configured ($TEMPLATE_DIR)."
fi
