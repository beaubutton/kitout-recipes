# atuin

Initialize [Atuin](https://atuin.sh) — a SQLite-backed replacement for your shell
history with full-text search and optional end-to-end-encrypted sync across
machines — in zsh.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:atuin >>>` … `# <<< recipes:atuin <<<`) containing:

```zsh
eval "$(atuin init zsh)"
```

Evaluated at shell startup, that installs Atuin's zsh hooks: it records commands
into `~/.local/share/atuin/history.db` and, **by default, rebinds `Ctrl-R` and the
Up arrow** to Atuin's fuzzy search UI. Everything outside the markers stays yours;
kitout only rewrites the block. No script.

## Requirements

- The `atuin` binary on PATH (`brew "atuin"`). Point the step's `needs` at your
  package step — this recipe wires up the shell init, it doesn't install atuin.
- A zsh login shell. For bash/fish, change `init zsh` accordingly.
- On first shell start after adopting, run `atuin import auto` **once** to backfill
  your existing shell history into Atuin's database.
- Sync is **opt-in and separate**: `atuin register` / `atuin login` + `atuin sync`.
  This recipe does none of that — it's local-only until you choose otherwise.

## Adopt

1. Paste the `[[step]]` from `step.toml`; add `needs = ["<atuin install step>"]`.
2. (Optional) opt out of the key rebinds — see Caveats — by editing the block:
   `eval "$(atuin init zsh --disable-up-arrow)"`.
3. Open a new shell, run `atuin import auto`, then hit `Ctrl-R`.

## Caveats

- **Takes effect in new shells**, not the one that ran the apply.
- **It rebinds `Ctrl-R` and Up by default.** If you want to keep the arrow key on
  the classic prefix-search, init with `--disable-up-arrow`; for `Ctrl-R`, use
  `--disable-ctrl-r`. Put those flags in the block.
- Atuin becomes your interactive history source; the plain `~/.zsh_history` still
  gets written but you'll navigate through Atuin.
- Load order matters if another tool also binds `Ctrl-R` (e.g. the `fzf-setup`
  recipe) — **whichever inits last wins.** Pick one to own `Ctrl-R`.

## Security

**Worth reading — this one touches a database of everything you type at the shell,
and can sync it off the machine.**

- **Local by default, but it records your command history.** `history.db` under
  `~/.local/share/atuin` captures your shell commands — which routinely include
  paths, hostnames, and sometimes **secrets typed inline** (tokens, `curl -H
  "Authorization: …"`, `PGPASSWORD=…`). That's already true of `~/.zsh_history`, but
  Atuin makes it queryable. Nothing leaves your machine unless you enable sync.
- **Sync is opt-in and end-to-end encrypted.** If you later run `atuin login`/`sync`,
  history is encrypted client-side with a key derived from your password before it
  reaches the server (Atuin's hosted service or your own), so the server can't read
  it — but you are then storing an encrypted copy of your history remotely. Keep the
  encryption key (`atuin key`) safe; losing it means losing sync access.
- **No privilege, no system files.** The recipe only edits your `~/.zshrc`; the
  `eval "$(atuin init zsh)"` line evals the output of the `atuin` binary you
  installed (its documented setup) in each interactive shell.
- **Reverse it:** remove the block from `~/.zshrc` (restores stock `Ctrl-R`), and
  `rm -rf ~/.local/share/atuin` to drop the history database. If you enabled sync,
  `atuin logout` and delete the account/server data too.
