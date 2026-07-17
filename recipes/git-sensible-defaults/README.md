# git-sensible-defaults

A set of opinionated global `git config` defaults most people set eventually.

## What it does

Writes these `--global` keys (only the ones that differ, so it's idempotent):

| Key | Why |
|---|---|
| `init.defaultBranch = main` | new repos start on `main` |
| `pull.rebase = true` | `git pull` rebases — no merge bubbles |
| `push.autoSetupRemote = true` | first `push` sets the upstream for you |
| `fetch.prune = true` | drop deleted remote branches on fetch |
| `rebase.autoStash = true` | auto stash/pop around a rebase |
| `rerere.enabled = true` | remember conflict resolutions |
| `diff.colorMoved = zebra` | highlight moved lines |
| `column.ui = auto` | columnar `git branch`/`status` output |

## Requirements

- `git` (any recent version).

## Adopt

1. Copy `git-sensible-defaults.sh` into your config's `steps/`.
2. Paste the `[[step]]`. Edit the list — these are *opinions*, not law.

## Caveats

- **`pull.rebase = true` changes `git pull` behavior** — it rebases your local
  commits onto the upstream instead of merging. If you rely on merge-on-pull, drop
  that line. `rebase.autoStash` softens it by stashing dirty work automatically.
- Writes to your **global** `~/.gitconfig`; per-repo config still overrides it.

## Security

None. Everything is user-scoped git configuration in your home directory — no
privilege, no network, no execution of anyone else's code. Reverse any key with
`git config --global --unset <key>`.
