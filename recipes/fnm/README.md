# fnm

Activate [fnm](https://github.com/Schniz/fnm) (Fast Node Manager) — a fast,
Rust-built Node.js version manager — in your interactive shell.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:fnm >>>` … `# <<< recipes:fnm <<<`) containing:

```sh
eval "$(fnm env --use-on-cd)"
```

`fnm env` exports the variables that put fnm's active-version directory on `PATH`;
`--use-on-cd` installs a shell hook so that `cd`-ing into a directory with a
`.node-version` or `.nvmrc` switches Node automatically. Everything outside the
markers stays yours; kitout only rewrites the block. No script.

This recipe installs the *shell hook*, not the fnm binary or any Node version —
see Requirements.

## Requirements

- The `fnm` binary on `PATH`: `brew "fnm"` (or fnm's official installer).
  Point the step's `needs` at whatever installs it so the hook lands after it.
- To actually get a Node: after adopting, run e.g. `fnm install --lts` and
  `fnm default lts-latest` yourself (kept out of this recipe on purpose).

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Add
`needs = ["<your fnm install step>"]`. Nothing to copy into `steps/`. Open a new
shell (or `source ~/.zshrc`), then `fnm --version` and `fnm install --lts`.

## Caveats

- **zsh only** as written. For bash, target `~/.bashrc` (same line works); fish and
  PowerShell need fnm's shell-specific `fnm env` output.
- Applies to **new** shells — `source ~/.zshrc` or open a new terminal for the
  session that ran `apply`.
- Ships **no Node version** — fnm with nothing installed leaves `node` unavailable
  until you `fnm install`.
- If you also run nvm/n/asdf/mise for Node, don't stack their shell hooks — pick one
  to own `PATH` for Node.

## Security

Low. It edits a marked block in your own `~/.zshrc` — no privilege, no network at
apply time, and it never touches the rest of the file.

The added line runs `eval "$(fnm env --use-on-cd)"` **every time you open a shell**,
executing whatever the on-PATH `fnm` binary emits — so the trust boundary is the
fnm binary (install it from a source you trust; that's the Requirements step's
concern). With `--use-on-cd`, entering a directory with a `.node-version`/`.nvmrc`
selects the version that file names (it selects, it does not auto-download or run
project code); later running that project's `node`/`npm` runs its code, same as any
repo. Reverse by deleting the block (or removing the recipe and re-applying).
