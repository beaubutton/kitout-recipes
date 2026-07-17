# bat-config

Configure [bat](https://github.com/sharkdp/bat)'s color theme and make it your
`man` pager, so man pages get syntax highlighting instead of plain roff.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:bat-config >>>` … `# <<< recipes:bat-config <<<`) containing:

```zsh
export BAT_THEME="ansi"
export MANPAGER="sh -c \"col -bx | bat -l man -p\""
export MANROFFOPT="-c"
```

- `BAT_THEME=ansi` — use bat's plain ANSI theme (matches your terminal's own
  color scheme) instead of a fixed syntax theme, so `bat` output stays legible on
  light or dark terminal backgrounds without you picking a specific theme.
- `MANPAGER` — pipes `man`'s output through `col -bx` (strip backspace-encoded
  bold/underline formatting) and then `bat -l man -p` (`-l man` picks bat's man-page
  grammar for highlighting, `-p`/`--plain` suppresses bat's line numbers and Git
  gutter since a man page isn't a file you're editing).
- `MANROFFOPT="-c"` — tells `man`'s roff formatter not to pre-apply the backspace
  encoding `col -bx` would otherwise have to strip on some systems, avoiding
  double-processing.

Everything outside the markers stays yours; kitout only rewrites the block. No
script.

## Requirements

- The `bat` binary on PATH (`brew "bat"`). Point the step's `needs` at your
  package step.
- A zsh login shell. For bash, the same three `export` lines work unchanged;
  drop them in `~/.bashrc` instead.

## Adopt

Paste the `[[step]]` from `step.toml`; add `needs = ["<bat install step>"]`. Open
a new shell, then run `man ls` (or any man page) to see it highlighted.

## Caveats

- On some Linux distributions the `bat` binary is packaged as `batcat`; on macOS
  via Homebrew it's `bat`, which this recipe assumes.
- `col` ships with macOS by default (`bsdmainutils`-equivalent); if you're on a
  minimal Linux base without it, install it or drop the `col -bx |` stage.
- This only changes the **pager** for `man`; it doesn't alias `cat` to `bat` — see
  the `modern-cli-aliases` recipe for that.

## Security

None. It only sets three environment variables in your own `~/.zshrc` — no
privilege, no network, no data collection. Remove the block and open a new shell
to revert to the default `man` pager and bat's default theme.
