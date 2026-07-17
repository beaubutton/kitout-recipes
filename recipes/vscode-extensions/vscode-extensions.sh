#!/usr/bin/env bash
# Install a user-editable list of VS Code extensions, idempotently. Edit EXTS
# below to add/remove extensions (use the "publisher.name" id shown on each
# extension's marketplace page, or `code --list-extensions` for what you have).
# Requires `code` on PATH (VS Code > Cmd+Shift+P > "Shell Command: Install
# 'code' command in PATH").
set -euo pipefail

EXTS=(
  editorconfig.editorconfig
  dbaeumer.vscode-eslint
  esbenp.prettier-vscode
)

if ! command -v code >/dev/null 2>&1; then
  echo "code CLI not found on PATH — install it from VS Code (Shell Command: Install 'code' command in PATH) and re-run." >&2
  exit 1
fi

installed="$(code --list-extensions 2>/dev/null || true)"
changed=0

for ext in "${EXTS[@]}"; do
  if printf '%s\n' "$installed" | grep -qix "$ext"; then
    continue
  fi
  code --install-extension "$ext" >/dev/null
  changed=1
done

if [ "$changed" -eq 0 ]; then
  echo "All ${#EXTS[@]} extensions already installed."
else
  echo "VS Code extensions installed/updated."
fi
