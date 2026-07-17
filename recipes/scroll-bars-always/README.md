# scroll-bars-always

Always show scroll bars, instead of macOS hiding them until you scroll (or
showing them only for a mouse).

## What it does

Writes one `NSGlobalDomain` key via kitout's `defaults` step (per-key change
detection):

| Key | Value | Effect |
|---|---|---|
| `AppleShowScrollBars` | `"Always"` | scroll bars are always visible (vs. `"WhenScrolling"` or `"Automatic"`) |

A string value, so `defaults read` renders it back verbatim as `Always` and
the step is honestly idempotent. No `kill` — apps pick this up per-window,
mostly on next launch (see Caveats).

## Requirements

None. Built-in macOS key; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`.

## Caveats

- **Takes effect per-window**, mostly on next app launch; already-open windows
  in already-running apps may not repaint until relaunched or until you open a
  new window.
- This is the same toggle as System Settings ▸ Appearance ▸ Show scroll bars;
  the other two choices are `"WhenScrolling"` and `"Automatic based on mouse or
  trackpad"` (written as `Automatic`), if you'd rather script one of those
  instead.

## Security

None. This is a single user-scoped UI preference in your own `NSGlobalDomain`
— no privilege, no network, no system files, no data touched. Reverse with
`defaults delete NSGlobalDomain AppleShowScrollBars` (restores the macOS
default, `Automatic`) or by writing `"WhenScrolling"`/`"Automatic"`.
