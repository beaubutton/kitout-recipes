#!/usr/bin/env bash
# Enable Git LFS for the current user by installing the global Git filters.
# Idempotent: a no-op once the clean filter is configured.
set -euo pipefail

if git config --global --get filter.lfs.clean >/dev/null 2>&1; then
  echo "Git LFS already enabled."
  exit 0
fi

git lfs install
echo "Git LFS enabled."
