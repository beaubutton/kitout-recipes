# menu-clock

Force a **24-hour** clock in the menu bar (and everywhere macOS formats time).

## What it does

Writes one `NSGlobalDomain` key via kitout's `defaults` step (per-key change
detection), then restarts the menu-bar processes so it shows immediately:

| Key | Value | Effect |
|---|---|---|
| `AppleICUForce24HourTime` | `true` | 24-hour time system-wide, including the menu-bar clock |

**Why this key and not `com.apple.menuextra.clock DateFormat`:** on Ventura and
later the menu-bar clock is owned by **Control Center**, and its
`com.apple.menuextra.clock` domain is sandboxed under a container — writes there
frequently don't stick and don't read back, which would leave the step forever
"pending." `AppleICUForce24HourTime` is a plain, un-sandboxed `NSGlobalDomain`
boolean that reliably round-trips and drives 24h formatting across the system, so
the step is honestly idempotent.

## Requirements

None. Built-in macOS key; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`. After applying, glance at the menu bar to confirm the clock flipped to
24-hour.

## Caveats

- **24-hour only.** An **analog** menu-bar clock is set via `com.apple.menuextra.clock
  IsAnalog`, but on current macOS that domain is Control-Center-sandboxed and
  unreliable to script — so this recipe deliberately doesn't ship it. Set analog by
  hand in System Settings ▸ Control Center ▸ Clock if you want it.
- The menu-bar clock refresh depends on restarting `ControlCenter`/`SystemUIServer`;
  on some macOS versions the visible change only lands after a **log out / in**,
  even though the preference is already written. Verify by eye.
- This changes 24h formatting **system-wide**, not just the menu bar — most apps
  that show times will follow it.

## Security

None. This is a single user-scoped locale/UI preference in your own
`NSGlobalDomain` — no privilege, no network, no system files, no data touched.
`killall SystemUIServer ControlCenter` restarts your own menu-bar processes (they
relaunch instantly). Reverse with `defaults delete NSGlobalDomain
AppleICUForce24HourTime` to fall back to your region's default (12- or 24-hour),
then log out / in.
