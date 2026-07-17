#!/usr/bin/env bash
# Set your terminal as the default handler for shell scripts (the
# public.unix-executable UTI), via `duti`. Change APP to your terminal's bundle
# id (e.g. com.mitchellh.ghostty, com.googlecode.iterm2, com.apple.Terminal).
# Idempotent.
set -euo pipefail

APP="com.mitchellh.ghostty"

if [ "$(duti -d public.unix-executable 2>/dev/null)" = "$APP" ]; then
  echo "${APP} is already the default terminal."
  exit 0
fi

# `shell` is duti's shortcut for the public.unix-executable role.
duti -s "$APP" shell
echo "${APP} set as the default terminal for shell scripts."
