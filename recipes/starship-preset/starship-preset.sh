#!/usr/bin/env bash
# Write a Starship preset to ~/.config/starship.toml (or $XDG_CONFIG_HOME).
#
# Uses `starship preset <name> -o <file>` to render one of Starship's built-in
# presets. Idempotent and NON-destructive: if a starship.toml already exists we
# leave it alone (so a hand-tuned config is never clobbered) and exit 0.
#
# Change STARSHIP_PRESET to any name from `starship preset --list` (e.g.
# nerd-font-symbols, pastel-powerline, plain-text-symbols, tokyo-night,
# gruvbox-rainbow, jetpack).
set -euo pipefail

STARSHIP_PRESET="${STARSHIP_PRESET:-nerd-font-symbols}"

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
config_file="$config_dir/starship.toml"

if [ -f "$config_file" ]; then
  echo "Starship config already present at $config_file — leaving it untouched."
  exit 0
fi

command -v starship >/dev/null 2>&1 || { echo "starship is required but not on PATH." >&2; exit 1; }

mkdir -p "$config_dir"
# Render to a temp file first so a failed preset render can't leave a half-written
# starship.toml (which the check would then treat as "done"). mktemp pre-creates
# the temp file, so we pass -f to let `starship preset -o` overwrite it (it refuses
# to write over an existing file otherwise).
tmp="$(mktemp "$config_dir/.starship.XXXXXX.toml")"
trap 'rm -f "$tmp"' EXIT
starship preset "$STARSHIP_PRESET" -o "$tmp" -f
mv "$tmp" "$config_file"
trap - EXIT

echo "Wrote Starship preset '$STARSHIP_PRESET' to $config_file."
