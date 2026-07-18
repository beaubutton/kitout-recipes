# zsh-history-opts

A big, shared, deduplicated zsh command history — every session sees every other
session's history, in real time, with junk filtered out.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:zsh-history-opts >>>` … `# <<< recipes:zsh-history-opts <<<`)
containing:

```zsh
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=$HOME/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS INC_APPEND_HISTORY EXTENDED_HISTORY
```

- `HISTSIZE`/`SAVEHIST` — keep 100k lines in memory and on disk (zsh's defaults are
  far smaller, usually 1000–2000).
- `HISTFILE` — pins the history file explicitly to `~/.zsh_history`.
- `SHARE_HISTORY` + `INC_APPEND_HISTORY` — every new command is appended to
  `HISTFILE` immediately and re-read into other open sessions, so history is live
  and shared across all your open terminals, not just saved on exit.
- `HIST_IGNORE_ALL_DUPS` — an older duplicate of a command is dropped when the new
  one is recorded, so the history stays deduplicated.
- `HIST_IGNORE_SPACE` — a line that starts with a **leading space** is not recorded
  at all (see Security).
- `HIST_REDUCE_BLANKS` — trims superfluous whitespace before recording.
- `EXTENDED_HISTORY` — records a timestamp and duration alongside each command
  (see Security).

Everything outside the markers stays yours; kitout only rewrites the block. No
script, no external tool.

## Requirements

- A zsh login shell. Pure `setopt`/env config — nothing to install.

## Adopt

Paste the `[[step]]` from `step.toml`. Nothing to copy into `steps/`. Open a new
shell to pick up the new options.

## Caveats

- **Existing `~/.zsh_history` is reused, not rewritten** — this only changes how
  future commands are recorded; it doesn't retroactively dedupe or timestamp old
  entries.
- **`SHARE_HISTORY` merges history live across open shells.** If you run several
  terminals side by side, expect to see each other's commands show up in `Up`/`Ctrl-R`
  search shortly after they run.
- If you already set any of `HISTSIZE`/`SAVEHIST`/`HISTFILE`/these `setopt`s
  elsewhere in `~/.zshrc` (e.g. inside an Oh My Zsh theme or a framework default),
  whichever line loads **last** wins — put this block after any framework init that
  also touches history.

## Security

**Worth reading before adopting — this changes what's recorded and for how long.**

- **History records everything you type.** That's true of stock zsh too, but a
  100k-line, shared, never-truncated history means more of it sticks around longer
  and is visible from every open shell. Commands routinely include paths, hostnames,
  and — if typed inline rather than sourced from a file or prompted — **secrets**
  (tokens, `curl -H "Authorization: …"`, `PGPASSWORD=…`). None of this leaves the
  machine; it's a plain-text file at `~/.zsh_history`.
- **`EXTENDED_HISTORY` adds a timestamp and duration to every entry.** More
  forensic detail persists locally (when you ran something, how long it took) — handy
  for your own review, but also more detail sitting in a file if that machine or
  file is ever exposed.
- **`HIST_IGNORE_SPACE` is your escape hatch.** Prefix any single command with a
  literal leading space and zsh skips recording it — the standard trick for keeping
  one-off secrets (`  export API_KEY=...`) out of history. It only works if you
  remember to use it *before* running the sensitive command.
- **No privilege, no network.** The recipe only edits your `~/.zshrc` and changes
  where/how `~/.zsh_history` is written.
- **Reverse it:** remove the block from `~/.zshrc` to fall back to zsh's built-in
  defaults. To scrub what's already recorded, edit or delete `~/.zsh_history`
  directly (that also affects Atuin/other importers if you've imported from it).
