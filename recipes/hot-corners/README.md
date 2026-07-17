# hot-corners

Assign screen-corner actions (Mission Control, Lock Screen, Desktop, etc.) via
`defaults` instead of clicking through System Settings.

## What it does

Writes a pair of `com.apple.dock` keys per corner via kitout's `defaults` step
(per-key change detection; Dock is restarted only if something actually
changed):

| Key | Meaning |
|---|---|
| `wvous-tl-corner` / `wvous-tl-modifier` | top-left action / required modifier |
| `wvous-tr-corner` / `wvous-tr-modifier` | top-right |
| `wvous-bl-corner` / `wvous-bl-modifier` | bottom-left |
| `wvous-br-corner` / `wvous-br-modifier` | bottom-right |

Each `-corner` key is an integer action code; each `-modifier` key is an
integer bitmask for a required modifier key (`0` = none, so the corner fires
on a bare pointer visit):

| Action | Code | Action | Code |
|---|---|---|---|
| (none / off) | `0` | Disable Screen Saver | `6` |
| Mission Control | `2` | Put Display to Sleep | `10` |
| Application Windows | `3` | Launchpad | `11` |
| Desktop | `4` | Notification Center | `12` |
| Screen Saver | `5` | Lock Screen | `13` |
| | | Quick Note | `14` |

| Modifier | Code |
|---|---|
| None | `0` |
| Shift | `131072` |
| Control | `262144` |
| Option | `524288` |
| Command | `1048576` |

The recipe ships **only bottom-left = Lock Screen** (code `13`, no modifier).
The other three corners are left alone — add `wvous-{tl,tr,br}-corner`/
`-modifier` pairs from the tables above to set them.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Add pairs for any
other corners you want, using the action/modifier codes above. Nothing to copy
into `steps/`.

## Caveats

- `kill = ["Dock"]` restarts the Dock so the change takes effect immediately;
  it relaunches in well under a second and Hot Corners are actually owned by
  the Dock process.
- Both keys for a corner must be written together — a `-corner` code with no
  matching `-modifier` key still works (macOS treats a missing modifier as
  `0`), but this recipe writes both explicitly so `plan`/`status` are honest
  about exactly what's set.
- Setting a corner back to "–" (off) means writing `0`, not deleting the key —
  there's no "unset" via this step; use `defaults delete com.apple.dock
  wvous-<corner>-corner` by hand if you'd rather remove it entirely.

## Security

None. These are user-scoped UI preferences in your own `com.apple.dock`
domain — no privilege, no network, no system files, no data touched. `killall
Dock` restarts your own Dock process (it relaunches instantly). Reverse any
corner with `defaults delete com.apple.dock wvous-<corner>-corner` (and
`-modifier`), then `killall Dock`.
