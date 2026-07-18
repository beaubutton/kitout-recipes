# vscode-settings

Seed a handful of sane defaults into **VS Code's user `settings.json`** without
clobbering anything you've already set.

## What it does

Uses kitout's `json-merge` step (`mode = "seed"`) to merge these keys into
`~/Library/Application Support/Code/User/settings.json`, **only where the key is
currently absent**:

| Key | Value | Effect |
|---|---|---|
| `editor.formatOnSave` | `true` | Run the active formatter on every save |
| `files.trimTrailingWhitespace` | `true` | Strip trailing whitespace on save |
| `files.insertFinalNewline` | `true` | Ensure files end with a newline |
| `editor.rulers` | `[80, 100]` | Vertical guide columns at 80 and 100 |
| `telemetry.telemetryLevel` | `"off"` | Disable VS Code's telemetry reporting |
| `workbench.editor.enablePreview` | `false` | Open files as full tabs, not ephemeral previews |

`mode = "seed"` means **write-if-absent**: kitout adds each key only when it's
missing from `settings.json`, so it never overwrites a value you've already
customized — that's also what makes it idempotent (once every key is present,
nothing pends).

## Requirements

- **VS Code**, launched at least once. `Code/User/settings.json` (and its parent
  directories) are created by VS Code itself on first run — if the file doesn't
  exist yet, kitout's `json-merge` creates it, but the *directory* needs VS Code
  to have run at least once. Point `needs` at your VS Code install/cask step.

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest.
2. Add `needs = ["<your VS Code step id>"]` if VS Code isn't already installed
   earlier in the DAG.
3. `kitout apply`, then open (or reload) VS Code to confirm the settings.

Nothing to copy into `steps/` — the value is inline; it's pure `json-merge`.

## Caveats

- **Seed, not converge.** If you later change any of these six keys by hand (or
  via VS Code's Settings UI), this step stays a no-op for that key and won't reset
  it. To force a value back to the recipe's default, delete that key from
  `settings.json` (or switch the step to `mode = "converge"`, which overwrites on
  every apply — including your own edits).
- **Six keys only.** This is a starting point, not a full settings profile — add
  more keys to the `value` table as you like; `json-merge` will seed whatever you
  add the same way. **Quote each key** (e.g. `"editor.wordWrap" = "on"`): VS Code
  settings are flat dotted keys, so an unquoted `editor.wordWrap` would nest as an
  `editor` object that VS Code ignores.
- `editor.rulers` is written as a whole array under `mode = "seed"` — if the key
  is already present with a different array, this step leaves it untouched (it
  doesn't merge array elements).

## Security

None. This is a user-scoped editor preference file — no privilege, no network,
no other app's data touched. The only substantive security-relevant change is
`telemetry.telemetryLevel = "off"`, which turns VS Code's own telemetry
reporting **off** (a reduction in what leaves your machine, not an increase).
Reverse it by removing the corresponding keys from
`~/Library/Application Support/Code/User/settings.json`.
