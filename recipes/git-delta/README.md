# git-delta

Render git diffs through [**delta**](https://github.com/dandavison/delta):
syntax-highlighted, word-level diffs with line numbers, nicer `git add -p`, and
readable 3-way merge conflicts.

## What it does

Wires delta into global git config:

| Key | Value | Why |
|---|---|---|
| `core.pager` | `delta` | pipe `git diff`/`git show`/`git log -p` through delta |
| `interactive.diffFilter` | `delta --color-only` | delta for `git add -p` and other interactive diffs |
| `delta.navigate` | `true` | `n`/`N` jump between files in the pager |
| `delta.line-numbers` | `true` | line numbers in the gutter |
| `delta.side-by-side` | `false` | split view off by default (flip to taste) |
| `merge.conflictStyle` | `zdiff3` (git 2.35+, else `diff3`) | show the merge base in conflicts |

`delta` is a **pager**, not a git subcommand — it replaces `less` for diff
output. The `merge.conflictStyle` bump is independent of delta but pairs well
with it and improves conflict readability regardless.

The step's `check` is satisfied once `core.pager=delta`; every write is compared
first, so re-applying is a no-op. Edit the `delta.*` lines in the script — they're
opinions.

## Requirements

- The **`delta`** binary on PATH. On macOS the Homebrew formula is **`git-delta`**
  (the binary is `delta`): `brew "git-delta"`. Point the step's `needs` at your
  brew step, or the script exits with a clear message if `delta` is missing.
- `git` 2.35+ to get `zdiff3` (older git falls back to `diff3` automatically).
- No sudo.

## Adopt

1. Copy `git-delta.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`.
3. If `git-delta` isn't installed by an earlier step, add
   `needs = ["<that step's id>"]`.
4. Flip `delta.side-by-side` to `true` in the script if you prefer split diffs.

## Caveats

- **Formula vs binary name mismatch:** the Homebrew *formula* is `git-delta` but
  the *binary* is `delta`. The `check` and script both probe `delta` — don't be
  surprised the names differ.
- delta styles honor your terminal's color scheme; if diffs look washed out, it's
  a terminal-theme issue, not this config. delta has extensive theming (`delta
  --show-config`) beyond what this recipe sets.
- Setting `core.pager = delta` affects **diff-like** output; other pagers (e.g.
  for `git log` without `-p`) are unaffected unless you also set them.

## Security

None. Everything is user-scoped git configuration — no privilege, no network, no
system state. delta is a local rendering tool that reads the diff git hands it and
prints colorized output; it makes no network calls and doesn't alter repo content.

Reverse any key with `git config --global --unset <key>` (e.g. `core.pager`,
`interactive.diffFilter`, the `delta.*` keys, `merge.conflictStyle`).
