#!/usr/bin/env bash
# Manage a marked region in /etc/hosts holding a small, user-editable
# ad/tracker blocklist. Only the lines between the markers are ever touched;
# everything else in the file is preserved byte-for-byte.
#
#   # >>> recipes:hosts-block >>>
#   0.0.0.0 example-tracker.com
#   # <<< recipes:hosts-block <<<
#
# Add/remove hostnames in the BLOCKLIST array below. Idempotent: exits 0 fast
# once the region already matches; otherwise rebuilds it via a temp file and
# copies that back over the real hosts file with sudo.
set -euo pipefail

HOSTS_FILE="${HOSTS_FILE:-/etc/hosts}"

begin='# >>> recipes:hosts-block >>>'
end='# <<< recipes:hosts-block <<<'

# Edit this list to taste — one hostname per entry, resolved to 0.0.0.0.
BLOCKLIST=(
  example-tracker.com
)

sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

desired_block() {
  local host
  # ${arr[@]+...} guards the empty-array case under `set -u` on bash 3.2
  # (macOS default), so clearing BLOCKLIST to reverse the block still works.
  for host in ${BLOCKLIST[@]+"${BLOCKLIST[@]}"}; do
    printf '0.0.0.0 %s\n' "$host"
  done
}

render_region() {
  printf '%s\n' "$begin"
  desired_block
  printf '%s\n' "$end"
}

current_region() {
  # Empty if the file is missing or the markers aren't present/balanced.
  awk -v b="$begin" -v e="$end" '
    $0 == b { inblock=1; print; next }
    $0 == e { if (inblock) { print; found=1 }; inblock=0; next }
    inblock { print }
    END { if (!found) exit 1 }
  ' "$HOSTS_FILE" 2>/dev/null || true
}

if [ -f "$HOSTS_FILE" ] && [ "$(current_region)" = "$(render_region)" ]; then
  echo "hosts-block region already up to date in ${HOSTS_FILE}."
  exit 0
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

if [ -f "$HOSTS_FILE" ] && grep -qF "$begin" "$HOSTS_FILE"; then
  # Rebuild: strip the old region out, then append the fresh one.
  awk -v b="$begin" -v e="$end" '
    $0 == b { inblock=1; next }
    $0 == e { inblock=0; next }
    inblock { next }
    { print }
  ' "$HOSTS_FILE" >"$tmp"
else
  # No existing region — keep the file as-is (or start empty if missing).
  if [ -f "$HOSTS_FILE" ]; then
    cat "$HOSTS_FILE" >"$tmp"
  fi
fi

# Ensure the file (as rebuilt so far) ends with exactly one trailing newline
# before we append, so the block starts on its own line.
if [ -s "$tmp" ] && [ "$(tail -c 1 "$tmp")" != "" ]; then
  printf '\n' >>"$tmp"
fi
render_region >>"$tmp"

sudo_cmd cp "$tmp" "$HOSTS_FILE"
sudo_cmd chmod 644 "$HOSTS_FILE"

echo "Updated hosts-block region in ${HOSTS_FILE}."
