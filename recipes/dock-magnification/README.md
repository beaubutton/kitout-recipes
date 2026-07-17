# dock-magnification

Turn on Dock magnification: icons grow as the pointer passes over them, from a
comfortable resting size.

## What it does

Writes three `com.apple.dock` keys via kitout's `defaults` step (per-key
change detection; the Dock is restarted only if something actually changed):

| Key | Value | Effect |
|---|---|---|
| `magnification` | `true` | enables the hover-grow effect |
| `largesize` | `64` | magnified (hovered) icon size, in points |
| `tilesize` | `48` | resting icon size, in points |

This is a different axis from [`dock-minimal`](../dock-minimal), which
auto-hides the Dock entirely. You can adopt both — `dock-minimal`'s
`autohide`/`autohide-delay`/`show-recents` keys and this recipe's
`magnification`/`largesize`/`tilesize` keys don't overlap.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Tune `largesize` /
`tilesize` to taste (keep `largesize` bigger than `tilesize`, or the effect is
invisible). Nothing to copy into `steps/`.

## Caveats

- `kill = ["Dock"]` restarts the Dock so the sizes and magnification apply
  immediately; it relaunches in well under a second.
- Magnification only shows while the pointer is actually over the Dock — it
  doesn't change the Dock's resting footprint beyond `tilesize`.
- Both size keys are written as integers; if you want a `largesize` smaller
  than or equal to `tilesize`, macOS just won't visibly magnify (harmless, but
  pointless).

## Security

None. These are user-scoped UI preferences in your own `com.apple.dock`
domain — no privilege, no network, no system files, no data touched. `killall
Dock` restarts your own Dock process (it relaunches instantly). Reverse any
key with `defaults delete com.apple.dock <key>` to restore the macOS default,
then `killall Dock`.
