# natural-scroll-off

Turn off "natural" scrolling — scrolling down moves you down the page/content,
the classic (pre-iOS-style) direction.

## What it does

Writes one `NSGlobalDomain` key via kitout's `defaults` step (per-key change
detection):

| Key | Value | Effect |
|---|---|---|
| `com.apple.swipescrolldirection` | `false` | classic/non-natural scroll direction for trackpad and mouse wheel |

A boolean, so `defaults read` renders it back as `0` and the step is honestly
idempotent. No `kill` — see the caveat below on when it takes effect.

## Requirements

None. Built-in macOS key; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`.

## Caveats

- **Takes effect on next login for some input devices.** The System Settings
  toggle updates live for most trackpads, but this scripted write can lag
  behind for certain Bluetooth mice/trackpads until you log out and back in.
  Verify by eye in System Settings ▸ Trackpad (or Mouse) ▸ Scroll direction.
- Applies to **both** trackpad and mouse-wheel scrolling — there's no
  per-device split at this key.

## Security

None. This is a single user-scoped UI preference in your own `NSGlobalDomain`
— no privilege, no network, no system files, no data touched. Reverse with
`defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true` (or
`defaults delete NSGlobalDomain com.apple.swipescrolldirection` to restore the
macOS default, which is natural-on).
