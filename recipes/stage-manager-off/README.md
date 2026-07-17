# stage-manager-off

Turn **Stage Manager** off — the same switch as the Control Center toggle or
System Settings → Desktop & Dock → Stage Manager.

## What it does

Writes one `com.apple.WindowManager` key via kitout's `defaults` step
(per-key change detection, no restart, no privilege):

| Key | Value | Effect |
|---|---|---|
| `GloballyEnabled` | `false` | Stage Manager is turned off system-wide |

## Requirements

None. Built-in macOS key (macOS 13 Ventura+, where Stage Manager shipped); no
packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`.

## Caveats

- **Takes effect on the next toggle or login**, not necessarily the instant
  `apply` runs — macOS reads this key when Stage Manager's own state machine
  next re-evaluates it. If you don't see the change immediately, log out and
  back in (or toggle Stage Manager once by hand) to force it to pick the value
  up.
- This only flips the global on/off switch. It doesn't touch related
  per-desktop keys like `AutoHide` or `HideWidgets`, which control Stage
  Manager's own behavior *while enabled* — irrelevant once it's off, but worth
  knowing if you re-enable it later and want to tune it.

## Security

None. This is a single user-scoped UI preference in your own
`com.apple.WindowManager` domain — no privilege, no network, no system files,
no data touched. Reverse it with `defaults write com.apple.WindowManager
GloballyEnabled -bool true` (or delete the key to fall back to the macOS
default), then log out / in (or toggle it by hand) if it doesn't show
immediately.
