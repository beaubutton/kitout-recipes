#!/usr/bin/env bash
# Set your default web browser via `defaultbrowser`. Change BROWSER to the id
# `defaultbrowser` prints for your browser (run `defaultbrowser` with no args to
# list them — e.g. edge, chrome, safari, firefox, brave).
#
# macOS shows a one-time consent dialog you must click; no tool can suppress it
# (it's Apple's anti-hijack protection), which is why the step is on-error = warn.
set -euo pipefail

BROWSER="edge"

if defaultbrowser 2>/dev/null | grep -q "^\* ${BROWSER}$"; then
  echo "${BROWSER} is already the default browser."
  exit 0
fi

defaultbrowser "$BROWSER"
echo "${BROWSER} set as default browser — confirm the macOS prompt if it appears."
