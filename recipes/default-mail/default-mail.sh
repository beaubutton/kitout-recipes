#!/usr/bin/env bash
# Set your default mailto: client (the app that opens when you click an email
# link), via `duti`. Change APP to your mail app's bundle id (e.g. com.apple.mail,
# com.microsoft.Outlook, com.readdle.smartemail-Mac). Idempotent.
#
# macOS guards the mailto: default like the default browser: changing it can pop
# a one-time consent dialog you must click, which no tool can suppress (Apple's
# anti-hijack protection). That's why the step is on-error = warn.
set -euo pipefail

APP="com.apple.mail"

if [ "$(duti -d mailto 2>/dev/null)" = "$APP" ]; then
  echo "${APP} is already the default mail client."
  exit 0
fi

# `mailto` is a URL scheme, not a document UTI — duti takes it with no role arg.
duti -s "$APP" mailto
echo "${APP} set as the default mail client — confirm the macOS prompt if it appears."
