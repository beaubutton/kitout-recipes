# menu-bar-autohide

Auto-hide the menu bar, reclaiming that strip of screen until you move the
pointer to the top edge.

## What it does

Writes one `NSGlobalDomain` key via kitout's `defaults` step (per-key change
detection, no privilege):

| Key | Value | Effect |
|---|---|---|
| `_HIHideMenuBar` | `true` | the menu bar hides until you move the pointer to the top of the screen |

This is the same switch as System Settings → Control Center →
"Automatically hide and show the menu bar."

## Requirements

None. Built-in macOS key; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`.

## Caveats

- **Takes effect after relaunch or login**, not necessarily the instant
  `apply` runs — this recipe deliberately doesn't `killall` anything, since
  the menu bar is rendered by `WindowServer`/`SystemUIServer` and restarting
  those is more disruptive than useful here. If you don't see the change
  immediately, log out and back in.
- This is the system-wide switch, not the "menu bar hidden only in full-screen
  apps" behavior (that's the default regardless of this key) — it hides the
  menu bar everywhere, including on the Desktop.
- Some menu-bar apps (Control Center modules, third-party menu extras) render
  slightly differently while the bar is auto-hidden and reappearing; that's a
  macOS/app-rendering quirk, not something this recipe controls.

## Security

None. This is a single user-scoped UI preference in your own
`NSGlobalDomain` — no privilege, no network, no system files, no data
touched. Reverse it with `defaults write NSGlobalDomain _HIHideMenuBar -bool
false` (or `defaults delete NSGlobalDomain _HIHideMenuBar` to fall back to the
macOS default), then log out / in if it doesn't show immediately.
