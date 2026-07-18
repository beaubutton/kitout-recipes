# reduce-motion

Turn on **Reduce Motion**: cuts the zoom/parallax/Spaces-switch animation
macOS otherwise plays, the same toggle as System Settings → Accessibility →
Motion → Reduce Motion.

## What it does

Writes one `com.apple.universalaccess` key via kitout's `defaults` step
(per-key change detection, no restart needed):

| Key | Value | Effect |
|---|---|---|
| `reduceMotion` | `true` | less animation on Spaces switches, app opens/closes, and other system transitions |

## Requirements

None. Built-in macOS key; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`.

## Caveats

- **May need a logout to fully apply.** Most of the effect is visible
  immediately, but a few system animations only pick up the change after you
  log out and back in.
- **Managed/MDM Macs:** kitout's `defaults` step type has no `on-error` field
  — a write is expected to just succeed. On a Mac under an MDM configuration
  profile that restricts `com.apple.universalaccess`, the write can silently
  fail to stick (the profile wins). If that happens, the step's `check` will
  keep reporting pending on every `plan`/`apply` — that's the honest signal
  something outside your control (the profile) is blocking it, not a bug in
  the step. There's nothing to fix locally in that case; ask whoever manages
  the profile.
- This is the same toggle as the Accessibility setting — it doesn't touch
  `com.apple.dock` animation keys like Dock-minimize-effect or Mission
  Control's own transition speed, which are separate preferences.

## Security

None. This is a single user-scoped accessibility/UI preference in your own
`com.apple.universalaccess` domain — no privilege, no network, no system
files, no data touched. Reverse it with `defaults write
com.apple.universalaccess reduceMotion -bool false` (or `defaults delete
com.apple.universalaccess reduceMotion` to fall back to the macOS default),
then log out / in if the reversal doesn't show immediately.
