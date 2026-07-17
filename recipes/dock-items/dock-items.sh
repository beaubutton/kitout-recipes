#!/usr/bin/env bash
# Curate the current user's Dock with dockutil: ensure a set of apps is present and
# a set of apps is absent. Operates on YOUR Dock only (no sudo). Idempotent: it
# checks dockutil's current --list and only adds/removes what's actually needed,
# restarting the Dock once at the end iff something changed.
#
# Edit ADD (label => /path/to/App.app) and REMOVE (labels) below to taste, and
# mirror the labels into the step's `check`.
set -euo pipefail

if ! command -v dockutil >/dev/null 2>&1; then
  echo "dockutil not found on PATH — install it (brew \"dockutil\")." >&2
  exit 1
fi

# Apps to ensure are IN the Dock: "Dock label" => "/Applications/…​.app"
# The label is what dockutil prints in column 1 of --list (usually the app name).
ADD_LABELS=(
  "Visual Studio Code"
)
ADD_PATHS=(
  "/Applications/Visual Studio Code.app"
)

# Apps to ensure are OUT of the Dock, by label (dockutil --list column 1).
REMOVE_LABELS=(
  "Music"
  "TV"
  "Podcasts"
  "News"
)

# dockutil --list emits: <label>\t<path>\t<...>. Isolate column 1 (tab-delimited)
# and exact-match the label, so labels containing spaces compare correctly.
in_dock() { dockutil --list 2>/dev/null | cut -f1 | grep -qxF "$1"; }

changed=0

# Additions: add by path only when the label isn't already present, and only when
# the .app actually exists (skip silently otherwise — don't fail the whole step).
for i in "${!ADD_LABELS[@]}"; do
  label="${ADD_LABELS[$i]}"; path="${ADD_PATHS[$i]}"
  if in_dock "$label"; then continue; fi
  if [ ! -e "$path" ]; then
    echo "Skipping '$label' — not installed at $path."
    continue
  fi
  dockutil --add "$path" --no-restart >/dev/null
  echo "Added '$label' to the Dock."
  changed=1
done

# Removals: remove by label only when present.
for label in "${REMOVE_LABELS[@]}"; do
  if in_dock "$label"; then
    dockutil --remove "$label" --no-restart >/dev/null
    echo "Removed '$label' from the Dock."
    changed=1
  fi
done

if [ "$changed" -eq 0 ]; then
  echo "Dock already curated."
  exit 0
fi

killall Dock 2>/dev/null || true
echo "Dock updated."
