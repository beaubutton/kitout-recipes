# finder-power-user

A sensible Finder preference set for people who live in the filesystem.

## What it does

Writes seven Finder/global `defaults` keys via kitout's `defaults` step (per-key
change detection; Finder is restarted only if something actually changed):

| Key | Effect |
|---|---|
| `AppleShowAllExtensions` | show every file extension |
| `AppleShowAllFiles` | show hidden (dot) files |
| `ShowPathbar` / `ShowStatusBar` | path + status bars |
| `_FXSortFoldersFirst` | folders sorted above files |
| `FXDefaultSearchScope` = `SCcf` | search the current folder, not the whole Mac |
| `_FXShowPosixPathInTitle` | full POSIX path in the window title |

No script and no `path` — it's pure declarative `defaults`.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Trim the `write` list to
taste. There's nothing to copy into `steps/`.

## Caveats

- Some keys apply to *new* Finder windows; the `kill = ["Finder"]` restart handles
  most of it, but a full effect sometimes wants a log-out/in.
- `FXDefaultSearchScope = "SCcf"` is the "current folder" scope; `"SCev"` is
  "this Mac" if you prefer the default.

## Security

None. These are user-scoped UI preferences in your own `defaults` domains — no
privilege, no network, no system files. The one thing worth a mention:
`AppleShowAllFiles` makes dotfiles **visible in Finder** (a display change, not an
access change — it grants no new permissions). Reverse any key with
`defaults delete <domain> <key>` or by flipping the value.
