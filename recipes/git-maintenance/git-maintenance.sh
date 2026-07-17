#!/usr/bin/env bash
# Enable git's background maintenance for a repo: `git maintenance start`
# registers the repo and installs an OS scheduler (launchd on macOS) that runs
# `git maintenance run` on hourly/daily/weekly cadences — prefetch, commit-graph,
# incremental-repack, loose-objects, pack-refs — so big repos stay fast and you
# never wait on a foreground `gc`. It also disables auto-gc for the repo.
#
# `git maintenance` is PER-REPO, so this manages one repo; add more [[step]]s
# (or loop) for others.
#
# TARGET REPO. Default: the current directory (only useful if you `cd` into the
# repo before running kitout). To maintain a specific repo, either export REPO
# in the environment kitout runs in, or replace the ${REPO:-$PWD} default below
# with an absolute path, e.g. REPO="$HOME/Source/big-monorepo". Whatever you
# choose, the `check` in step.toml must resolve to the SAME repo — the two are
# independent probes with no shared variable.
#
# Idempotent: `git maintenance start` records the repo's absolute path in the
# GLOBAL maintenance.repo list; we skip if it's already registered. The step's
# check mirrors that.
set -euo pipefail

REPO="${REPO:-$PWD}"

if ! git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not a git repo: $REPO — set REPO in this script to a real repository." >&2
  exit 1
fi

# Absolute path of the repo's top level, matching how git records it globally.
top="$(git -C "$REPO" rev-parse --show-toplevel)"

# Already enrolled? maintenance.repo is a global, multi-valued key.
if git config --global --get-all maintenance.repo 2>/dev/null \
  | grep -qxF "$top"; then
  echo "Background maintenance already enabled for $top."
  exit 0
fi

git -C "$REPO" maintenance start
echo "Background maintenance enabled for $top."
