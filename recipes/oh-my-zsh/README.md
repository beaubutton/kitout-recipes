# oh-my-zsh

Install [Oh My Zsh](https://ohmyz.sh) unattended into `~/.oh-my-zsh`, without
changing your login shell or clobbering your `~/.zshrc`.

## What it does

Runs Oh My Zsh's official `install.sh` in **unattended** mode with the flags that
make it safe to run from an automated apply:

- `--unattended` / `RUNZSH=no` — the installer doesn't drop you into an interactive
  `zsh` subshell at the end (which would hang a non-interactive apply).
- `CHSH=no` — it does **not** run `chsh` to change your default login shell.
- `--keep-zshrc` / `KEEP_ZSHRC=yes` — an existing `~/.zshrc` is left in place; the
  installer won't overwrite it or back it up to `~/.zshrc.pre-oh-my-zsh`.

The step's `check` probes for the `~/.oh-my-zsh` directory, so `plan`/`status` are
honest and the installer never runs a second time.

## Requirements

- `git` (macOS ships it via the Command Line Tools; or `brew "git"`). `curl` is
  built in. Point the step's `needs` at whatever installs git if it isn't present.
- Network access to `raw.githubusercontent.com` and `github.com` (the installer
  clones the framework repo).

## Adopt

1. Copy `oh-my-zsh.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. If you also manage `~/.zshrc` with kitout (e.g. a `block-in-file` for aliases or
   `eval "$(starship init zsh)"`), order those **after** this step. Because this
   recipe passes `--keep-zshrc`, the installer **never writes a `~/.zshrc`** — not
   even on a fresh machine — so kitout (or you) owns that file end to end. You must
   add a `source $ZSH/oh-my-zsh.sh` line yourself for the framework to load (see
   Caveats).

## Caveats

- **It does not change your default shell.** By design (`CHSH=no`). If your login
  shell isn't already `zsh`, run `chsh -s /bin/zsh` yourself, or add a separate step.
- **Themes/plugins are configured in `~/.zshrc`,** which this recipe deliberately
  leaves to you — installing the framework is separate from enabling a theme.
- **Installed ≠ active.** With `--keep-zshrc`, the installer never touches or creates
  `~/.zshrc`, so Oh My Zsh is on disk but **not sourced** — on a fresh machine *and*
  on one with an existing `~/.zshrc` — until you add `source $ZSH/oh-my-zsh.sh` (with
  `export ZSH="$HOME/.oh-my-zsh"`) to your `~/.zshrc` yourself.

## Security

**This downloads and executes a remote install script — the standard, documented
Oh My Zsh bootstrap, but worth understanding.**

- **Remote code execution by design.** The script runs
  `sh -c "$(curl -fsSL …/ohmyzsh/…/install.sh)"`, i.e. it fetches and runs code from
  `raw.githubusercontent.com` at apply time. You are trusting the Oh My Zsh project
  and GitHub's TLS. This is the same command the project's homepage tells you to run;
  the recipe adds nothing on top. If you want to audit or pin it, download
  `install.sh` once, vendor it into your repo, and point the script at the local copy
  instead of `curl`.
- **Unpinned `master`.** The URL tracks the `master` branch, so you run whatever is
  there at apply time, not a fixed revision. To pin, swap `master` for a tag/commit
  SHA, or vendor `install.sh` as above.
- **`-fsSL` fails closed on HTTP errors** and uses TLS — a truncated or 404 response
  won't be piped to `sh` as a partial script. But under `set -e` a *failed* download
  leaves `sh -c ""` running empty and exiting 0, so the script explicitly checks that
  `~/.oh-my-zsh` exists afterward and exits non-zero if the install silently no-op'd.
- **No privilege.** Everything lands under `~/.oh-my-zsh`. With `--keep-zshrc` the
  installer writes **no** `~/.zshrc` (not even on a fresh box) and touches no existing
  one. No `sudo`, no system files.
- **Non-destructive to your shell config.** `--keep-zshrc` and `CHSH=no` mean it
  won't create or rewrite `~/.zshrc` or change your login shell behind your back.
- **Reverse it:** Oh My Zsh ships `uninstall_oh_my_zsh`, or just
  `rm -rf ~/.oh-my-zsh` and remove its `source` line from `~/.zshrc`.
