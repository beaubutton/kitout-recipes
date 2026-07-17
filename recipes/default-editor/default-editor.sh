#!/usr/bin/env bash
# Set your editor as the default handler for text and source-code files, via
# `duti`. Change APP to your editor's bundle id (e.g. com.microsoft.VSCode,
# com.sublimetext.4, dev.zed.Zed, com.apple.TextEdit). Idempotent.
#
# We claim the two umbrella UTIs most text/code files conform to:
#   public.plain-text  — .txt, .md, config files, dotfiles, …
#   public.source-code — .py, .rs, .js, .sh, and other source
# Individual extensions can still declare their own handler; those override
# these umbrellas and aren't touched here (see the recipe README).
set -euo pipefail

APP="com.microsoft.VSCode"

utis="public.plain-text public.source-code"

# Converged only when every UTI we manage already points at APP.
converged=1
for uti in $utis; do
  if [ "$(duti -d "$uti" 2>/dev/null)" != "$APP" ]; then
    converged=0
    break
  fi
done
if [ "$converged" -eq 1 ]; then
  echo "${APP} is already the default editor for text and source code."
  exit 0
fi

# `editor` is duti's role for "opens for editing" (vs `viewer`/`all`).
for uti in $utis; do
  duti -s "$APP" "$uti" editor
done
echo "${APP} set as the default editor for text and source-code files."
