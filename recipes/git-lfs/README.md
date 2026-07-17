# git-lfs

Enable [Git LFS](https://git-lfs.com) for your user by installing its global Git
filters.

## What it does

Runs `git lfs install`, which writes the `filter.lfs` clean/smudge/process entries
into your global `~/.gitconfig`. After this, any repo with a `.gitattributes`
declaring LFS-tracked paths works without a per-repo `git lfs install`.

The step's `check` probes `git config --global --get filter.lfs.clean`, so `plan`
and `status` are honest and the script is skipped once it's set.

## Requirements

- The `git-lfs` package (macOS: `brew "git-lfs"`; kitout's `brewfile`/`brew` step).
  Point the step's `needs` at whatever installs it.

## Adopt

1. Copy `git-lfs.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. If `git-lfs` isn't already installed by an earlier step, add
   `needs = ["<that step's id>"]`.

## Caveats

- Global only. It doesn't touch existing repos' checkouts; run `git lfs pull` in a
  repo if its large files came down as pointers before LFS was set up.

## Security

None. It writes user-scoped Git config in your home directory — no privilege, no
network, no system state. Reverse with `git lfs uninstall`.
