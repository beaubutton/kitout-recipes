# pnpm-home

Put pnpm's global bin directory (`PNPM_HOME`) on `PATH`, so packages installed
with `pnpm add -g` are runnable in a new shell.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:pnpm-home >>>` … `# <<< recipes:pnpm-home <<<`) containing:

```zsh
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
```

`PNPM_HOME` is pnpm's documented macOS default for where global installs place
their bin shims (`~/Library/pnpm`). The `case` guard checks whether
`$PNPM_HOME` is already present anywhere in `$PATH` (as a colon-delimited
segment, not a substring match) before prepending it, so sourcing this block
repeatedly — or a shell that already inherited the export from a parent
process — never stacks up duplicate `PATH` entries. Everything outside the
markers stays yours; kitout only rewrites the block. No script.

## Requirements

- The `pnpm` binary on `PATH`: `brew "pnpm"`. Point the step's `needs` at your
  package step.
- A zsh login shell. For bash, target `~/.bashrc` instead (same lines work).

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Add
`needs = ["<your pnpm install step>"]`. Nothing to copy into `steps/`. Open a
new shell, `pnpm add -g <package>`, and confirm its binary runs.

## Caveats

- **Hardcodes `~/Library/pnpm`** as `PNPM_HOME`. If you've configured pnpm to
  use a different global bin dir, edit the block to match.
- Applies to **new** shells — `source ~/.zshrc` or open a new terminal for the
  session that ran `apply`.
- Doesn't install pnpm or any global package — it only fixes `PATH`.

## Security

None beyond a normal `PATH` edit. It manages a marked block in your own
`~/.zshrc` — no privilege, no network, and it never touches the rest of the
file. Putting `PNPM_HOME` on `PATH` means a binary placed there shadows one
later in `PATH` — keep `~/Library/pnpm` under your control (it's your home
dir) and don't let untrusted processes write to it. Anything you later
`pnpm add -g` runs its package's console-scripts, the normal exposure of a
package manager, not something this recipe adds. Reverse by removing the
block from `~/.zshrc`.
