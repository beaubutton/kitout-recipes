# fast-keyboard

Make the keyboard repeat as fast as macOS allows, and turn a held key into a
**repeat** instead of the accented-character popover.

## What it does

Writes three `NSGlobalDomain` keys via kitout's `defaults` step (per-key change
detection):

| Key | Value | Effect |
|---|---|---|
| `KeyRepeat` | `1` | repeat interval; `1` is *faster* than the Settings slider's minimum (`2`) |
| `InitialKeyRepeat` | `10` | delay before repeat starts (≈150 ms; the slider bottoms out at `15`) |
| `ApplePressAndHoldEnabled` | `false` | holding a key repeats it instead of showing the accent popover |

`KeyRepeat`/`InitialKeyRepeat` are stored as integers; `defaults read` renders
them back as `1`/`10`, so the step is honestly idempotent. No `kill` — no daemon
owns these; they load per-process at launch.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`. Tune the two integers if `1`/`10` feels too aggressive.

## Caveats

- **Takes effect on next launch / login.** Already-running apps read these at
  startup, so log out and back in (or restart the app) for the full effect.
- `ApplePressAndHoldEnabled = false` disables the **hold-for-accent** popover
  system-wide. If you type accented characters by holding `e`/`o`/etc., you'll
  lose that — use the Character Viewer or a dead-key layout instead. (Some apps,
  notably certain Electron editors, set their own per-app value that overrides
  this.)
- `KeyRepeat = 1` is below the Settings UI range; if a value feels *too* fast,
  the Settings slider will read as blank until you pick a value it recognizes.

## Security

None. These are user-scoped input preferences in your own `NSGlobalDomain` — no
privilege, no network, no system files, no data touched. Reverse any key with
`defaults delete NSGlobalDomain <key>` (restores the macOS default) or by writing
your preferred value.
