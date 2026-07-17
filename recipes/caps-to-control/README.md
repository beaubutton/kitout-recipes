# caps-to-control

Remap **Caps Lock → Control**, and make it stick across reboots.

## What it does

Two parts:

1. **Runtime remap** via `hidutil property --set` — maps the Caps Lock HID usage
   (`0x700000039`) to Left Control (`0x7000000E0`). This takes effect immediately
   but **resets on reboot** (hidutil mappings are not persistent).
2. **Persistence** via a per-user LaunchAgent at
   `~/Library/LaunchAgents/com.kitout.caps-to-control.plist` with `RunAtLoad`, so the
   same `hidutil` remap runs at every login.

The script writes the LaunchAgent (only if its content differs), (re)loads it with
`launchctl bootstrap`, and applies the mapping now. The step's `check` requires
**both** conditions — the plist exists **and** the mapping is currently active — so
`plan`/`status` are honest and a reboot-only-reset state shows as pending.

Note: `hidutil property --set` takes usage codes in **hex** (`0x700000039`,
`0x7000000E0`), but `hidutil property --get` reads them back in **decimal**
(`30064771129`, `30064771296`). The `check` and the script's idempotency probe grep
for the decimal forms — grepping for the hex would never match `--get`'s output and
would make the step re-run forever.

No `sudo`: HID *user*-key remapping and `~/Library/LaunchAgents` are user-scoped.

## Requirements

- macOS with `hidutil` (`/usr/bin/hidutil`, present since 10.12).
- No packages, no privilege.

## Adopt

1. Copy `caps-to-control.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`.
3. `kitout apply`. The remap is live immediately and reapplies on each login.

To pick a **different** target (e.g. Escape for vim users), change `DST` in the
script to the destination usage code (Escape is `0x700000029`) — and update the two
places that hold the **decimal** form: `DST_DEC` in the script and the matching
decimal in the `check` (Escape `0x700000029` = `30064771113`). Convert with
`printf '%d\n' 0x700000029`. Keep `SRC` as Caps Lock unless you're remapping a
different key.

## Caveats

- **This is a full remap, not "Caps Lock also acts as Control."** Caps Lock's
  toggle/LED function is gone while the mapping is active. (macOS's built-in
  Keyboard → Modifier Keys can also do Caps→Control if you prefer the GUI; this
  recipe is the scriptable, declarative version.)
- The mapping is **global to the login session**, applied to all currently-attached
  keyboards; hot-plugging a keyboard re-applies via hidutil's usage-page matching.
- If macOS's own Modifier-Keys setting *also* remaps Caps Lock, the two can fight —
  pick one. This recipe assumes Modifier Keys is left at default.
- Takes effect immediately for the current session; the LaunchAgent covers future
  logins/reboots.

## Security

Low, and user-scoped — no privilege, no network, no data touched.

- **What it changes:** a keyboard key mapping for your login session, plus a
  LaunchAgent in your own `~/Library/LaunchAgents` that re-applies it at login. Both
  are things you can inspect and edit as your user.
- **Keylogging note:** this is *not* a key**logger** — it doesn't capture, store, or
  transmit keystrokes. It only tells the HID layer "when you see Caps Lock, report
  Control instead." Nothing records what you type.
- **LaunchAgent scope:** the agent runs a single, visible command
  (`/usr/bin/hidutil property --set …`) at login. It's not a persistent daemon doing
  anything else. You can read the exact plist it installs.
- **Reverse it:** remove the mapping now with
  `hidutil property --set '{"UserKeyMapping":[]}'`, then
  `launchctl bootout gui/$(id -u)/com.kitout.caps-to-control` and delete
  `~/Library/LaunchAgents/com.kitout.caps-to-control.plist`.
