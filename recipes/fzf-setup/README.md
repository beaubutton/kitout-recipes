# fzf-setup

Enable [fzf](https://github.com/junegunn/fzf)'s zsh integration — the **key
bindings** (`Ctrl-R` history search, `Ctrl-T` file picker, `Alt-C` fuzzy `cd`) and
**fuzzy tab completion**.

## What it does

Appends a small managed block to `~/.zshrc` that sources fzf's shell integration:

```zsh
# >>> kitout:fzf >>>
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
# <<< kitout:fzf <<<
```

`fzf --zsh` (fzf **≥ 0.48**) prints the key-bindings + completion script on stdout;
sourcing it at shell startup is the current, install-script-free way to wire fzf
into zsh — and because it's evaluated live, the integration always matches your
installed fzf version. The `command -v fzf` guard means the line is harmless on a
machine where fzf later goes missing.

The step's `check` greps `~/.zshrc` for the `kitout:fzf` marker, so `plan`/`status`
are honest and the block is written exactly once.

## Requirements

- The `fzf` binary on PATH, **version ≥ 0.48** (`brew "fzf"` is well past this).
  Point the step's `needs` at your package step.
- A zsh login shell (this recipe manages `~/.zshrc`).

## Adopt

1. Copy `fzf-setup.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest; add
   `needs = ["<fzf install step>"]`.
3. Open a **new** shell, then hit `Ctrl-R` to confirm the fuzzy history search.

## Caveats

- **Takes effect in new shells**, not the one that ran the apply.
- **fzf ≥ 0.48 only.** The script refuses (exit 1) on an older fzf rather than
  writing a broken line — upgrade fzf, or use the classic
  `$(brew --prefix)/opt/fzf/install` installer instead.
- Uses `>>` append rather than kitout's `block-in-file` step so the whole thing is
  one script; if you'd rather have kitout own the block declaratively, lift the two
  lines into a `block-in-file` step (see the `zoxide` recipe) — but that path can't
  version-gate fzf the way this script does.
- Doesn't set `FZF_DEFAULT_COMMAND` or theme colors — that's your `~/.zshrc` to own.

## Security

Low blast radius. It edits **your own `~/.zshrc`** (no privilege, no system files)
and adds one guarded `source <(fzf --zsh)` line. The one thing to be clear about:
that line executes the output of `fzf --zsh` in every new interactive shell — i.e.
you're trusting the `fzf` binary you installed to emit a benign integration script
(it does; this is fzf's documented setup). No network access at apply time or shell
startup. Reverse by deleting the `# >>> kitout:fzf >>>` … `# <<< kitout:fzf <<<`
block from `~/.zshrc`.
