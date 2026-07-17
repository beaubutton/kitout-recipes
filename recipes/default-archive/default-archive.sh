#!/usr/bin/env bash
# Set the default handler for .zip archives, via `duti`, on the
# public.zip-archive UTI. Change APP to your extractor's bundle id (e.g.
# com.apple.archiveutility, com.aone.keka, cx.c3.theunarchiver). Idempotent.
#
# Scope is deliberately just .zip (public.zip-archive). Other formats — .rar,
# .7z, .tar.gz — have their own UTIs; add them (e.g. public.tar-archive,
# org.7-zip.7-zip-archive) if your tool should own those too.
set -euo pipefail

APP="com.aone.keka"
UTI="public.zip-archive"

if [ "$(duti -d "$UTI" 2>/dev/null)" = "$APP" ]; then
  echo "${APP} is already the default handler for .zip archives."
  exit 0
fi

# `all` role: an extractor is both the viewer and the opener for the archive.
duti -s "$APP" "$UTI" all
echo "${APP} set as the default handler for .zip archives."
