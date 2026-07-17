#!/usr/bin/env bash
# Opinionated global git defaults. Idempotent — only writes a key when it differs,
# so it's a fast no-op once applied. Edit the list to taste.
set -euo pipefail

set_cfg() {
  local key="$1" val="$2"
  if [ "$(git config --global --get "$key" 2>/dev/null)" = "$val" ]; then
    return 0
  fi
  git config --global "$key" "$val"
  echo "  set $key = $val"
}

set_cfg init.defaultBranch    main    # new repos start on main
set_cfg pull.rebase           true    # pull = rebase, no merge bubbles
set_cfg push.autoSetupRemote  true    # first push auto-sets the upstream
set_cfg push.default          simple
set_cfg fetch.prune           true    # drop deleted remote branches on fetch
set_cfg rebase.autoStash      true    # stash/pop around a rebase
set_cfg rerere.enabled        true    # remember conflict resolutions
set_cfg diff.colorMoved       zebra   # highlight moved lines in diffs
set_cfg column.ui             auto

echo "git defaults applied."
