#!/usr/bin/env bash
# Set your default PDF viewer, via `duti`, on the com.adobe.pdf UTI. Change APP
# to your viewer's bundle id (e.g. com.apple.Preview, com.google.Chrome,
# org.mozilla.firefox, net.sourceforge.skim-app.skim). Idempotent.
#
# Note: macOS's concrete UTI for PDF files is com.adobe.pdf — that's where
# LaunchServices binds the handler for real .pdf documents. The abstract
# public.pdf UTI conforms to it, but `duti -d public.pdf` does NOT walk the
# conformance tree, so it reports "no default handler" even when one is set.
# We use com.adobe.pdf throughout so the script, the check, and reality agree.
set -euo pipefail

APP="com.apple.Preview"
UTI="com.adobe.pdf"

if [ "$(duti -d "$UTI" 2>/dev/null)" = "$APP" ]; then
  echo "${APP} is already the default PDF viewer."
  exit 0
fi

# `viewer` is duti's role for "opens for viewing"; the right one for a reader.
duti -s "$APP" "$UTI" viewer
echo "${APP} set as the default PDF viewer."
