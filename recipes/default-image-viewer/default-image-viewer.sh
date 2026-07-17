#!/usr/bin/env bash
# Set your default image viewer, via `duti`. Change APP to your viewer's bundle
# id (e.g. com.apple.Preview, net.sourceforge.xnview.XnViewMP,
# com.flyingmeat.Acorn). Idempotent.
#
# macOS binds each concrete image format to its own handler, and setting the
# public.image umbrella does NOT reliably cascade to them. So we claim the
# common formats explicitly. Add any you also want (e.g. public.svg-image,
# org.webmproject.webp) to the `utis` list — and keep the `check` pointed at one
# you manage.
set -euo pipefail

APP="com.apple.Preview"

utis="public.png public.jpeg public.tiff public.heic com.compuserve.gif public.camera-raw-image"

# Converged only when every format we manage already points at APP.
converged=1
for uti in $utis; do
  if [ "$(duti -d "$uti" 2>/dev/null)" != "$APP" ]; then
    converged=0
    break
  fi
done
if [ "$converged" -eq 1 ]; then
  echo "${APP} is already the default image viewer."
  exit 0
fi

for uti in $utis; do
  duti -s "$APP" "$uti" viewer
done
echo "${APP} set as the default image viewer."
