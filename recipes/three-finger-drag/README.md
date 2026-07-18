# three-finger-drag

Enable **three-finger drag** — sweep three fingers on the trackpad to drag a
window or select content, instead of click-and-drag.

## What it does

Writes two keys via kitout's `defaults` step (per-key change detection):

| Domain | Key | Value | Effect |
|---|---|---|---|
| `com.apple.AppleMultitouchTrackpad` | `TrackpadThreeFingerDrag` | `true` | three-finger drag for the built-in trackpad driver |
| `com.apple.driver.AppleBluetoothMultitouch.trackpad` | `TrackpadThreeFingerDrag` | `true` | three-finger drag for Bluetooth (and current-generation built-in) trackpads |

Both driver domains are written so the recipe works unmodified regardless of
which trackpad hardware/driver actually owns the setting on your Mac. Booleans,
so `defaults read` renders them back as `1` and the step is honestly
idempotent.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`.

## Caveats

- **Needs a re-login** (or a System Settings ▸ Trackpad round-trip) to
  reliably take effect on some macOS versions, even though the preference is
  already written — this key has historically been one of the flakier
  `defaults`-settable trackpad prefs. Verify by eye afterward.
- Three-finger drag can also be toggled from System Settings ▸ Accessibility
  ▸ Pointer Control ▸ Trackpad Options — that path and this one write the same
  keys.
- No `kill` in this step — there's no menu-bar/Dock-style process to restart;
  the driver reads these keys on demand.

## Security

None. These are user-scoped accessibility/input preferences in your own
preference domains — no privilege, no network, no system files, no data
touched. Reverse either key with `defaults delete <domain>
TrackpadThreeFingerDrag` (restores the macOS default, off).
