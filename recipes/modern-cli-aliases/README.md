# modern-cli-aliases

Swap the classic CLI tools for their modern replacements in interactive shells —
`ls`→`eza`, `cat`→`bat`, `grep`→`rg`, `find`→`fd`.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:aliases >>>` … `# <<< recipes:aliases <<<`). Everything outside the
markers stays yours; kitout only rewrites the block. No script.

## Requirements

- The tools you alias to: `brew "eza"`, `"bat"`, `"ripgrep"`, `"fd"`. Point the
  step's `needs` at your package step, or trim the block to the tools you install.

## Adopt

Paste the `[[step]]` from `step.toml`. Delete any alias whose tool you don't want.
Nothing to copy into `steps/`. Open a new shell to pick them up.

## Caveats

- **Aliases apply to interactive shells only** — they do **not** affect scripts,
  `Makefile`s, or anything non-interactive, so aliasing `grep`/`find` won't silently
  change tool behavior in automation.
- `bat`, `eza`, `rg`, `fd` take **different flags** than the tools they replace.
  Interactive muscle memory mostly transfers; if a habitual flag errors, you've hit
  a difference (e.g. `grep -P` vs `rg`).

## Security

None. It edits a marked block in your own `~/.zshrc` — no privilege, no network,
and it never touches the rest of the file. Remove the recipe and re-apply (or delete
the block) to revert.
