#!/usr/bin/env bash
# Install krew — the kubectl plugin manager — into ~/.krew (or $KREW_ROOT).
# This mirrors krew's documented bootstrap: download the release tarball for this
# OS/arch from the krew-team GitHub release, verify no shell pipe is involved, and
# run `krew install krew` to self-install. No sudo; everything stays under $HOME.
# Idempotent: a no-op once kubectl-krew is present.
set -euo pipefail

krew_root="${KREW_ROOT:-$HOME/.krew}"
if [ -x "$krew_root/bin/kubectl-krew" ]; then
  echo "krew already installed at $krew_root."
  exit 0
fi

command -v kubectl >/dev/null || { echo "kubectl not on PATH — install it first." >&2; exit 1; }

# Map uname to krew's release asset naming.
os="$(uname | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"
case "$arch" in
  x86_64) arch="amd64" ;;
  aarch64 | arm64) arch="arm64" ;;
esac
asset="krew-${os}_${arch}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

# Download the tarball to disk (no curl|bash), unpack, then let krew install itself.
url="https://github.com/kubernetes-sigs/krew/releases/latest/download/${asset}.tar.gz"
curl -fsSLo "${asset}.tar.gz" "$url"
tar zxf "${asset}.tar.gz"
KREW_ROOT="$krew_root" "./${asset}" install krew

echo "krew installed. Add \"$krew_root/bin\" to your PATH:"
echo "  export PATH=\"\${KREW_ROOT:-\$HOME/.krew}/bin:\$PATH\""
echo "Then: kubectl krew update && kubectl krew install <plugin>"
