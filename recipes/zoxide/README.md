# zoxide

Initialize [zoxide](https://github.com/ajeetdsouza/zoxide) — a smarter `cd` that
learns your most-used directories — in zsh.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:zoxide >>>` … `# <<< recipes:zoxide <<<`) containing:

```zsh
eval "$(zoxide init zsh)"
```

That line, evaluated at every shell startup, defines the `z` command (jump to a
frecency-ranked directory) and `zi` (interactive pick). Everything outside the
markers stays yours; kitout only rewrites the block. No script.

## Requirements

- The `zoxide` binary on PATH (`brew "zoxide"`). Point the step's `needs` at your
  package step.
- A zsh login shell. For other shells, change `init zsh` to `init bash`/`init fish`
  and the `target`.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest; add
`needs = ["<zoxide install step>"]`. Nothing to copy into `steps/`. Open a new
shell, `cd` around a bit, then `z <partial-name>` to jump.

## Caveats

- **Takes effect in new shells**, not the one that ran the apply.
- zoxide only knows directories you've visited *since* it started tracking — the
  database (`~/.local/share/zoxide/db.zo`) builds up as you navigate.
- To have `z` also **replace** `cd`, init with `--cmd cd`
  (`eval "$(zoxide init zsh --cmd cd)"`); the default keeps `cd` untouched and adds
  `z`.
- Load order: zoxide's own docs ask that this line come **after** `compinit` runs (so
  `zi`'s completions register). The block-in-file step appends to the end of `~/.zshrc`,
  which already satisfies that for a normal setup; if you use a prompt like Starship or a
  plugin manager, keep this after their init lines too (the hook itself is order-tolerant).

## Security

None beyond a normal shell-config edit. It manages a marked block in **your own
`~/.zshrc`** — no privilege, no network, and it never touches the rest of the file.
The `eval "$(zoxide init zsh)"` line runs the `zoxide` binary you installed and
evals its integration output in every interactive shell; that's zoxide's documented
setup and the output is a benign shell hook. zoxide records the directory paths you
visit in a local database under `~/.local/share/zoxide` (a privacy note, not a
security hole — no data leaves the machine). Reverse by removing the recipe and
re-applying, or deleting the block.
