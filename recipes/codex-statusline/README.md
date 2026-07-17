# codex-statusline

Seed the **Codex CLI TUI status line** — the footer showing model, approval mode,
context usage, and directory — into `~/.codex/config.toml`.

## What it does

Codex's terminal UI has a configurable footer driven by `tui.status_line`, an
**ordered array of item identifiers** it renders left to right. This recipe uses
kitout's `toml-merge` step (`mode = "seed"`) to add:

```toml
tui.status_line = ["model", "approval", "context_usage", "cwd"]
```

to `~/.codex/config.toml`. Valid items are `model`, `approval`, `context_usage`,
`session_id`, `sandbox`, `cwd`, and `spinner`; reorder or trim the array to taste.
No script — it's pure declarative `toml-merge`.

**`mode = "seed"` means write-if-absent**: kitout adds `tui.status_line` only when
it isn't already set, so it never overrides a footer you've customized (which is
also what makes the step idempotent — present → nothing pends).

## Requirements

- Codex CLI (it reads `~/.codex/config.toml`). No packages, no privilege, no
  network.

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest.
2. Edit the `status_line` array to the items and order you want.
3. `kitout apply`, then restart Codex to pick up the footer.

The interactive `/statusline` command in Codex is the friendly front end for this
same setting (toggle/reorder items in a picker). To hide the bar entirely, set
`tui.status_line = null` in `config.toml`.

Nothing to copy into `steps/`.

## Caveats

- **Seed, not converge.** If you later change `tui.status_line` by hand (or via
  `/statusline`), this step stays a no-op and won't reset it. To force the recipe's
  value back, remove the key first, or switch to `mode = "converge"` (which
  overwrites yours on every apply).
- **Item identifiers are Codex-defined and can change across versions.** An unknown
  item is ignored by Codex; if the footer looks wrong after a Codex upgrade, check
  its docs for the current item names.
- **Dotted-key merge.** kitout merges `tui.status_line` into the `[tui]` table,
  leaving other `[tui]` and top-level keys in `config.toml` intact.

## Security

- **What it changes:** merges one `tui.status_line` array into
  `~/.codex/config.toml`, user-scoped. No privilege, no network, nothing
  downloaded; the rest of your Codex config is left intact.
- **No code, no command execution.** Unlike Claude's `statusLine` (which runs a
  shell command), Codex's status line is a **fixed list of built-in display fields
  by name** — it can't run arbitrary commands, so there's no execution surface here
  to worry about. This is purely a UI-layout preference.
- **Mild information exposure.** The bar shows model, approval mode, context usage,
  and the current directory on screen. That's visible in screenshares/recordings;
  drop `cwd` from the array if the working path is sensitive. Nothing here reveals
  tokens, keys, or file contents.
- **Reverse it:** remove the `[tui] status_line` line from `~/.codex/config.toml`
  (or set it to `null` to hide the bar), or drop the step.
