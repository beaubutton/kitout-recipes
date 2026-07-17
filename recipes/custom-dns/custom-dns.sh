#!/usr/bin/env bash
# Set the DNS resolvers for a network service via networksetup. Edit SERVICE
# and DNS below to taste — SERVICE must match a name from
# `networksetup -listallnetworkservices` exactly (e.g. "Wi-Fi", "Ethernet").
# Idempotent: exits 0 fast once the service already resolves through exactly
# these servers, in this order.
set -euo pipefail

SERVICE="${SERVICE:-Wi-Fi}"
DNS="${DNS:-1.1.1.1 1.0.0.1}"

sudo_cmd() { if [ -n "${SUDO_ASKPASS:-}" ]; then sudo -A "$@"; else sudo "$@"; fi; }

current="$(networksetup -getdnsservers "$SERVICE" 2>/dev/null || true)"
# shellcheck disable=SC2086 # DNS is an intentionally word-split list of IPs
desired="$(printf '%s\n' $DNS)"

if [ "$current" = "$desired" ]; then
  echo "DNS for '${SERVICE}' already set to: ${DNS}"
  exit 0
fi

if ! networksetup -listallnetworkservices 2>/dev/null | grep -qxF "$SERVICE"; then
  echo "Network service '${SERVICE}' not found. Run: networksetup -listallnetworkservices" >&2
  exit 1
fi

# shellcheck disable=SC2086 # DNS is an intentionally word-split list of IPs
sudo_cmd networksetup -setdnsservers "$SERVICE" $DNS

echo "DNS for '${SERVICE}' set to: ${DNS}"
