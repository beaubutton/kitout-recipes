# reduce-transparency

Turn on **Reduce transparency** — make the menu bar, Dock, sidebars, Notification
Center, and sheets **opaque** instead of blurring what's behind them. The same
toggle as System Settings → Accessibility → Display → Reduce transparency.

## What it does

Writes one accessibility `defaults` key via kitout's `defaults` step (no privilege,
no restart):

| Domain | Key | Value |
|---|---|---|
| `com.apple.universalaccess` | `reduceTransparency` | `true` |

macOS renders translucent chrome (the "vibrancy" blur) throughout the UI; setting
this key replaces those blurs with solid fills. This also **slightly reduces GPU
compositing work** and improves legibility of text over busy wallpapers. macOS
10.10 (Yosemite)+.

No script and no `path` — pure declarative `defaults`.

## Requirements

None. Built-in macOS accessibility key; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. There's nothing to copy
into `steps/`. To turn it back off, set `value = false` (or delete the key — see
Security).

## Caveats

- **Full effect needs a log out / log in.** Some surfaces (menu bar, Dock) go
  opaque promptly; others only fully re-render after you log back in. The recipe
  intentionally does **not** force a logout or kill an app (nothing restarts the
  compositor cleanly).
- This is a display preference, not a security control — it changes how chrome is
  drawn, nothing about what's visible or accessible.
- It's independent of Dark/Light mode and of "Reduce motion"; it only affects
  translucency.

## Security

None. `reduceTransparency` is a user-scoped accessibility **display** preference in
your own `com.apple.universalaccess` domain — no privilege, no network, no system
files, no data touched. It changes only how macOS draws translucent UI chrome
(opaque vs blurred).

Reverse it with `defaults write com.apple.universalaccess reduceTransparency -bool false`
or `defaults delete com.apple.universalaccess reduceTransparency` (then log out /
in).
