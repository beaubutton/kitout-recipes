# press-and-hold-off

Disable the hold-a-key **accent-character popover** — holding a key repeats it
instead, the behavior most terminal/editor/vim users expect.

## What it does

Writes one `NSGlobalDomain` key via kitout's `defaults` step (per-key change
detection):

| Key | Value | Effect |
|---|---|---|
| `ApplePressAndHoldEnabled` | `false` | holding a key repeats it instead of showing the accent popover |

A boolean, so `defaults read` renders it back as `0` and the step is honestly
idempotent. No `kill` — no daemon owns this key; apps read it at launch.

This is the same key the [`fast-keyboard`](../fast-keyboard) recipe also sets
as part of a bundle — **use this recipe on its own** if you only want the
accent popover gone without touching `KeyRepeat`/`InitialKeyRepeat` (e.g.
you're happy with the default repeat speed, or `fast-keyboard` isn't in your
manifest). Applying both is harmless; they converge the same key to the same
value.

## Requirements

None. Built-in macOS key; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`. Skip this recipe if you've already adopted `fast-keyboard`, which
sets the same key alongside repeat-rate tuning.

## Caveats

- **Takes effect on next launch / login.** Already-running apps read this at
  startup, so log out and back in (or restart the app) for the full effect.
- **Trades away the accent picker.** If you type accented characters (é, ñ,
  ü, …) by holding a letter key and picking from the popover, you'll lose that
  path — use the Character Viewer (Globe key ▸ Emoji & Symbols, or Edit ▸
  Emoji & Symbols) or a dead-key-capable keyboard layout instead.
- Some apps (notably certain Electron-based editors) set their own per-app
  value that overrides this global default.

## Security

None. This is a single user-scoped input preference in your own
`NSGlobalDomain` — no privilege, no network, no system files, no data touched.
Reverse with `defaults delete NSGlobalDomain ApplePressAndHoldEnabled` (restores
the macOS default, the accent popover) or by writing `true`.
