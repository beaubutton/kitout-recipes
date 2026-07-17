# asdf

Activate [asdf](https://asdf-vm.com) — the multi-language version manager
(Node, Ruby, Python, Java, and dozens more via plugins) — in zsh, for
**current** asdf (v0.16+).

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:asdf >>>` … `# <<< recipes:asdf <<<`) containing:

```zsh
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
```

**asdf v0.16 rewrote the tool in Go** and changed how it activates: there is no
longer an `asdf.sh` to `source`. Activation is just putting the shim directory
on `PATH` — the line above does exactly that, defaulting to `~/.asdf` unless
you've set `ASDF_DATA_DIR` elsewhere. Everything outside the markers stays
yours; kitout only rewrites the block. No script.

## Requirements

- The `asdf` binary on `PATH`, **v0.16 or later**: `brew "asdf"` (current
  Homebrew ships the Go rewrite). Point the step's `needs` at whatever installs
  it.
- A zsh login shell. For bash, target `~/.bashrc` (the same `PATH` line works
  — no shell-specific `asdf.sh` to source anymore).

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Add
`needs = ["<your asdf install step>"]`. Nothing to copy into `steps/`. Open a
new shell, then `asdf plugin add <name>` and `asdf install <name> <version>`.

## Caveats

- **This is the v0.16+ (Go) activation only.** If you're pinned to an older
  asdf (pre-0.16, the Bash implementation), the correct line is instead:
  ```zsh
  . "$(brew --prefix asdf)/libexec/asdf.sh"
  ```
  Check `asdf version` before adopting; mixing the two activation styles for
  the wrong asdf version leaves shims unresolved.
- Applies to **new** shells — `source ~/.zshrc` or open a new terminal for the
  session that ran `apply`.
- Ships **no language plugins or runtimes** — `asdf plugin add`/`asdf install`
  are on you.
- If you also run a dedicated version manager for the same language (fnm,
  pyenv, jenv, …), don't stack their shell hooks with asdf for that language —
  pick one to own `PATH` for it.

## Security

Low. It edits a marked block in your own `~/.zshrc` — no privilege, no network
at apply time, and it never touches the rest of the file.

The added line only prepends a directory to `PATH`; it doesn't `eval` any
command output (unlike tools that `eval "$(... init ...)"`), so there's no
dynamic code execution baked into the shell startup itself. asdf's **shims**
under that directory intercept language commands (`node`, `ruby`, `python`,
…) and dispatch to the version you've selected — the normal exposure of a
version manager, and only for languages/runtimes you've explicitly installed
via `asdf plugin add` / `asdf install`. Reverse by deleting the block (or
removing the recipe and re-applying).
