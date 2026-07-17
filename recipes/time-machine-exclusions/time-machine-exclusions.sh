#!/usr/bin/env bash
# Exclude dev-cruft paths from Time Machine backups via `tmutil addexclusion`.
# This only changes WHAT Time Machine backs up — it does not delete anything,
# does not touch other backup tools, and is fully reversible per-path with
# `tmutil removeexclusion PATH`.
# Edit PATHS below to add/remove entries. All defaults are user-owned (no sudo
# needed); if you add a system path you'd need sudo_cmd + on-error stays "warn".
set -euo pipefail

PATHS=(
  "$HOME/Library/Caches"
  "$HOME/.cache"
  "$HOME/Developer/build"
)

is_excluded() {
  tmutil isexcluded "$1" 2>/dev/null | grep -q '^\[Excluded\]'
}

pending=()
for p in "${PATHS[@]}"; do
  [ -e "$p" ] || continue
  is_excluded "$p" || pending+=("$p")
done

if [ "${#pending[@]}" -eq 0 ]; then
  echo "All Time Machine exclusions already in place."
  exit 0
fi

for p in "${pending[@]}"; do
  tmutil addexclusion "$p"
  echo "Excluded from Time Machine: $p"
done
