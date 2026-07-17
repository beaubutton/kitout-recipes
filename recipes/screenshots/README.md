# screenshots

Save screenshots to **`~/Screenshots`** instead of littering the Desktop, drop the
fake window drop-shadow, and force **PNG**.

## What it does

A `script` recipe that creates `~/Screenshots` and writes three
`com.apple.screencapture` keys, then restarts `SystemUIServer` to refresh the
capture UI:

| Key | Value | Effect |
|---|---|---|
| `location` | `$HOME/Screenshots` | where new screenshots are written |
| `disable-shadow` | `true` | no drop-shadow border on window captures (⇧⌘4 then Space) |
| `type` | `png` | pin the file format to PNG (this is also the stock default; set explicitly so a machine an earlier tool switched to `jpg`/`heic` is corrected) |

The `screencapture` tool reads these keys fresh from your preferences at each
capture, so the settings take effect on the next screenshot regardless. The
`killall SystemUIServer` is just a harmless nudge to refresh the menu-bar/UI
process immediately (it relaunches instantly).

**Why a script, not a plain `defaults` step:** `defaults` can't `mkdir` the target
directory, and `location` must be an **absolute** path — macOS `defaults` does not
expand `~`, so a literal `~/Screenshots` would create a folder named `~` in your
home. The script writes `$HOME/Screenshots` and creates it first. The `check`
mirrors all three keys plus the directory, so `plan`/`status` stay honest.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

1. Copy `screenshots.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.

Prefer a different folder? Change `dir` in the script **and** the path in the
step's `check` so they agree.

## Caveats

- The `check` compares `location` against `$HOME/Screenshots` at plan time. If you
  edit the destination, update both the script and the `check` or the step will
  always look pending.
- `disable-shadow` only affects **window** captures (the ones that would otherwise
  get a shadow); full-screen and region captures are unchanged.
- Existing screenshots on the Desktop are **not** moved — this only changes where
  *new* ones land.

## Security

None. These are user-scoped preferences in your own `com.apple.screencapture`
domain, plus a `mkdir` in your home directory — no privilege, no network, no
system files. `killall SystemUIServer` restarts your own menu-bar/UI process (it
relaunches instantly). Reverse with `defaults delete com.apple.screencapture
location` (and `disable-shadow`, `type`) to restore the Desktop/PNG defaults; the
`~/Screenshots` folder is left in place for you to remove if you want.
