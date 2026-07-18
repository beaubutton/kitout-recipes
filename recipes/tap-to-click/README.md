# tap-to-click

Enable **tap-to-click** — tap the trackpad to click, no physical press needed.

## What it does

Writes three keys via kitout's `defaults` step (per-key change detection):

| Domain | Key | Value | Effect |
|---|---|---|---|
| `com.apple.driver.AppleBluetoothMultitouch.trackpad` | `Clicking` | `true` | tap-to-click for Bluetooth (and current-generation built-in) trackpads |
| `com.apple.AppleMultitouchTrackpad` | `Clicking` | `true` | tap-to-click for the built-in trackpad driver |
| `NSGlobalDomain` | `com.apple.mouse.tapBehavior` | `1` | legacy global mirror some apps still read |

Both driver domains are written because System Settings itself writes
whichever one matches your actual trackpad hardware — shipping both makes the
recipe work unmodified on any Mac. All three are booleans/integers that
`defaults read` renders back plainly, so the step is honestly idempotent.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`.

## Caveats

- **`tapBehavior` sometimes only sticks when written `-currentHost`** (i.e.
  `defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior 1`),
  which is a separate, host-scoped preference domain that kitout's `defaults`
  step does not set. On most Macs the plain write here is sufficient and the
  driver-domain keys above are what actually drive the trackpad; if tapping
  doesn't register after applying, verify **by eye** in System Settings ▸
  Trackpad ▸ Point & Click, and if needed run the `-currentHost` variant by
  hand.
- May need a **re-login** (or System Settings ▸ Trackpad round-trip) for the
  driver keys to visibly take on some macOS versions, even though the
  preference is already written.
- No `kill` in this step — the trackpad driver reads these on demand; if a
  change doesn't show immediately, toggle the setting once in System Settings
  to force a re-read.

## Security

None. These are user-scoped input preferences in your own preference domains
— no privilege, no network, no system files, no data touched. Reverse any key
with `defaults delete <domain> <key>` (restores the macOS default).
