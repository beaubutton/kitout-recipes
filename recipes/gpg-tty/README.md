# gpg-tty

Point GPG's pinentry at your current terminal, so passphrase prompts show up
where you're typing instead of failing or popping up somewhere unexpected.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:gpg-tty >>>` … `# <<< recipes:gpg-tty <<<`) containing:

```zsh
export GPG_TTY=$(tty)
```

`gpg-agent`'s `pinentry` program uses `GPG_TTY` to know which terminal to attach
to when it needs to prompt for a passphrase (curses-based `pinentry-curses`) or to
decide it should hand off to a GUI prompt (`pinentry-mac`, etc.). Without it set —
or set stale, e.g. after reattaching a `tmux`/`screen` session — GPG operations
that need a passphrase can hang or fail with `gpg: signing failed: Inappropriate
ioctl for device`. Setting it fresh in every new shell keeps it pointed at the
terminal you're actually in.

Everything outside the markers stays yours; kitout only rewrites the block. No
script.

## Requirements

- The `gpg` binary on PATH (`brew "gnupg"`). Point the step's `needs` at your
  package step.
- A zsh login shell. For bash, the same line works unchanged in `~/.bashrc`.

## Adopt

Paste the `[[step]]` from `step.toml`; add `needs = ["<gpg install step>"]`. Open
a new shell — `GPG_TTY` is now set for any `gpg`/`gpg-agent` operation in that
session. Pairs naturally with the `commit-signing-gpg` recipe (GPG-signed git
commits need a working pinentry to unlock the signing key).

## Caveats

- **Set per-shell, not once.** `GPG_TTY=$(tty)` must be re-evaluated in each new
  shell (that's what this block does on every `~/.zshrc` source) — a value cached
  from a previous terminal or session will point at a `tty` that no longer exists.
- If you use `tmux`/`screen` and reattach in a new terminal, the underlying tty
  device can change; open a fresh pane/window (which re-sources `~/.zshrc`) rather
  than reusing an old one if signing suddenly stops prompting correctly.
- If you use a GUI pinentry (`pinentry-mac`) exclusively, this still doesn't hurt —
  `GPG_TTY` is simply unused by the GUI path — but it's required the moment you're
  on `pinentry-curses` or SSH'd in without a GUI session.

## Security

None beyond what GPG itself already does. This only sets one environment variable
(`GPG_TTY`) telling `gpg-agent` which terminal to prompt on — it doesn't touch
keys, doesn't change signing behavior, and doesn't talk to the network. No
privilege required. Reverse it by removing the block from `~/.zshrc`.
