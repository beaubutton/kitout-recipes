# less-config

Sensible default flags for `less` — raw colors survive, short output doesn't page,
searches are smart-case — and no search-history file left on disk.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:less-config >>>` … `# <<< recipes:less-config <<<`) containing:

```zsh
export LESS="-R -F -i -M"
export LESSHISTFILE=-
```

`LESS` is read as a default set of flags every time `less` starts (including when
invoked indirectly, e.g. as `git`'s or `man`'s pager):

- `-R` — pass through raw ANSI color escapes instead of showing them as literal
  garbage, so colored output (`git diff`, `bat`, `grep --color`) renders correctly.
- `-F` — **quit immediately if the content fits on one screen**, instead of paging.
- `-i` — searches are case-**insensitive** unless your search string contains an
  uppercase letter, in which case it becomes case-sensitive ("smart case").
- `-M` — a more verbose/informative status prompt (shows position as a percentage,
  line numbers, filename).

`LESSHISTFILE=-` disables the `~/.lesshst` search-history file entirely (that file
would otherwise persist every search pattern and mark you've ever entered in `less`).

Everything outside the markers stays yours; kitout only rewrites the block. No
script.

## Requirements

- `less` — ships with macOS by default. Nothing to install.
- A zsh login shell. For bash, the same two `export` lines work unchanged; drop
  them in `~/.bashrc` instead.

## Adopt

Paste the `[[step]]` from `step.toml`. Nothing to copy into `steps/`. Open a new
shell (or `export` the two lines directly) to pick it up immediately.

## Caveats

- **This recipe deliberately omits `-X`.** `-X` (don't clear the screen / don't
  send the terminal-init/deinit sequences) is a common pairing with `-F`, but on
  some terminal emulators and multiplexers it leaves stray escape sequences or
  breaks the alternate-screen handoff, which can visually corrupt the prompt after
  `less` exits. `-F` alone already covers the common case (short output doesn't
  page); if you want `-X` too, add it to the block yourself and verify your
  terminal handles it cleanly.
- `-F` means a short `git log` or `grep` result won't page at all — if you expect
  to always land in a pager (e.g. to scroll back), this can surprise you the first
  time. It's the standard trade for "don't make me press q on trivial output."
- If another tool also sets `LESS` (some framework themes do), whichever export
  runs **last** in `~/.zshrc` wins.

## Security

**Minor privacy note, otherwise none.**

- `LESSHISTFILE=-` is itself a small **privacy improvement**: without it, `less`
  writes every search pattern and mark you type into `~/.lesshst` in plain text,
  which can include fragments of whatever you were searching for in logs or files
  (occasionally sensitive strings). Setting it to `-` turns that off entirely — no
  history file is written, and any existing `~/.lesshst` stops growing (delete it
  manually if you want the old entries gone).
- Everything else is display-only flags. **No privilege, no network.** The recipe
  only edits your `~/.zshrc`.
- **Reverse it:** remove the block from `~/.zshrc` and open a new shell.
