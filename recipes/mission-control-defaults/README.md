# mission-control-defaults

Keep your Spaces in a stable, predictable order and group windows by app in
Mission Control.

## What it does

Writes two `com.apple.dock` keys via kitout's `defaults` step (per-key change
detection; the Dock is restarted only if something actually changed):

| Key | Value | Effect |
|---|---|---|
| `mru-spaces` | `false` | Spaces stay in the order you arranged them, instead of macOS reshuffling to put the most-recently-used Space first |
| `expose-group-apps` | `true` | Mission Control / App Exposé groups each app's windows together instead of scattering them |

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`.

## Caveats

- `kill = ["Dock"]` restarts the Dock so both changes apply immediately; it
  relaunches in well under a second.
- `mru-spaces = false` only stops *reordering* — it doesn't change how you
  switch Spaces (still `Ctrl+←/→` or a four-finger swipe); the Spaces bar in
  Mission Control just stops shuffling under you.
- `expose-group-apps` affects the Mission Control window layout only; it does
  not change Dock app-grouping or `expose-animation-duration`.

## Security

None. These are user-scoped UI preferences in your own `com.apple.dock`
domain — no privilege, no network, no system files, no data touched. `killall
Dock` restarts your own Dock process (it relaunches instantly). Reverse either
key with `defaults delete com.apple.dock <key>` to restore the macOS default,
then `killall Dock`.
