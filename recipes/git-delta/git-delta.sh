#!/usr/bin/env bash
# Configure git to render diffs through delta (https://github.com/dandavison/delta):
# syntax-highlighted, word-level diffs as the pager, plus nicer interactive diffs
# and 3-way merge conflicts. Requires the `delta` binary on PATH (brew: git-delta).
#
# Idempotent: every write is compared first, so a converged config is a no-op.
# The step's check mirrors the core condition (core.pager = delta). Edit the
# delta.* opinions to taste.
set -euo pipefail

if ! command -v delta >/dev/null 2>&1; then
  echo "delta not found on PATH — install it (brew install git-delta)." >&2
  exit 1
fi

set_cfg() {
  local key="$1" val="$2"
  if [ "$(git config --global --get "$key" 2>/dev/null)" = "$val" ]; then
    return 0
  fi
  git config --global "$key" "$val"
  echo "  set $key = $val"
}

# Core wiring: delta as the pager, and as the filter for `git add -p` etc.
set_cfg core.pager "delta"
set_cfg interactive.diffFilter "delta --color-only"

# delta features (opinions — trim to taste).
set_cfg delta.navigate true                # n / N to jump between files
set_cfg delta.line-numbers true            # show line numbers in the gutter
set_cfg delta.side-by-side false           # set true if you prefer split view

# 3-way conflict style pairs well with delta's conflict rendering. zdiff3
# needs git 2.35+; fall back to diff3 on older git. `sort -V` puts the lower
# version first, so if 2.35 sorts first the installed git is >= 2.35.
git_ver="$(git --version | awk '{print $3}')"
lowest="$(printf '%s\n2.35\n' "$git_ver" | sort -V | head -n1)"
if [ "$lowest" = "2.35" ]; then
  set_cfg merge.conflictStyle zdiff3
else
  set_cfg merge.conflictStyle diff3
fi

echo "git configured to use delta."
