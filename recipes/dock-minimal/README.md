# dock-minimal

A minimal, stay-out-of-the-way Dock: **auto-hide** with **no reveal delay**, no
"recent applications" section, and **small** tiles.

## What it does

Writes four `com.apple.dock` keys via kitout's `defaults` step (per-key change
detection; the Dock is restarted only if something actually changed):

| Key | Value | Effect |
|---|---|---|
| `autohide` | `true` | Dock hides until you push the pointer into its edge |
| `autohide-delay` | `0` | no delay before it reveals (default is a short pause) |
| `show-recents` | `false` | removes the trailing "recent applications" group |
| `tilesize` | `40` | smaller icons (default is roughly 48–64) |

`autohide-delay` is written as integer `0`; the Dock reads it as a number and
`defaults read` renders it back as `0`, so the step is honestly idempotent.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Trim the `write` list or
tune `tilesize` to taste. Nothing to copy into `steps/`.

## Caveats

- The `kill = ["Dock"]` restart makes the change immediate; the Dock relaunches on
  its own in well under a second.
- `autohide-delay = 0` removes the *reveal* delay but not the slide **animation**.
  If you want the reveal fully instant, also set `autohide-time-modifier` — but
  that key is a **float**, which kitout's `defaults` step doesn't support, so set
  it by hand (`defaults write com.apple.dock autohide-time-modifier -float 0`) if
  you want it.
- Setting `autohide-delay` back to the macOS default means `defaults delete`, not a
  numeric value — there's no documented "default" integer.

## Security

None. These are user-scoped UI preferences in your own `com.apple.dock` domain —
no privilege, no network, no system files, no data touched. `killall Dock`
restarts your own Dock process (it relaunches instantly). Reverse any key with
`defaults delete com.apple.dock <key>` to restore the macOS default, then
`killall Dock`.
