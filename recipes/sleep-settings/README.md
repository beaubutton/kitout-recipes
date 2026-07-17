# sleep-settings

Set display/disk sleep timers and disable **Power Nap**, via `pmset`.

## What it does

Applies three power-management settings to **all power sources** (`pmset -a`):

| Setting | Default here | Meaning |
|---|---|---|
| `displaysleep` | `10` | minutes idle before the display sleeps |
| `disksleep` | `10` | minutes idle before spinning disks sleep |
| `powernap` | `0` | Power Nap off (no background wakes for mail/updates/Time Machine while asleep) |

Values are minutes; `0` = never. The script reads the current per-source config
(`pmset -g custom`) and only writes what differs, so it's idempotent. The step's
`check` reads the same source (unprivileged) and passes when all three match.

This deliberately does **not** set `sleep` (full system sleep) — that's the setting
most people tune per-machine (and on desktops you often want it off entirely). Add a
`pmset -a sleep <n>` line if you want to manage it too.

## Requirements

- `sudo = true` in your manifest — `pmset` writes need admin. kitout exposes
  `SUDO_ASKPASS`; the script uses `sudo -A` so `apply -y` runs unattended.
  (Reading state with `pmset -g custom` is unprivileged.)

## Adopt

1. Copy `sleep-settings.sh` into your config's `steps/`.
2. Edit `DISPLAYSLEEP` / `DISKSLEEP` / `POWERNAP` to taste, and update the same
   three values in the `check` in `step.toml`.
3. Ensure your manifest has `sudo = true`.

## Caveats

- **`-a` applies to both AC and battery.** If you want different timers on battery
  vs. wall power, split into `pmset -b …` (battery) and `pmset -c …` (charger) calls
  and adjust the check accordingly.
- **Disabling Power Nap** means the Mac won't wake to check mail, run Time Machine,
  or fetch updates while asleep — intended here (predictable sleep), but know the
  tradeoff.
- `disksleep` only affects spinning disks; it's a no-op on SSD-only Macs (harmless).
- Some settings are hardware/model-dependent (e.g. a desktop may not expose
  `powernap`); `pmset` ignores keys it doesn't support, and the check reflects
  whatever the machine actually reports.

## Security

Low, and it doesn't touch auth, the network, or your data. It changes
**system-wide power policy** (hence sudo), not user files.

- **Privilege used:** `sudo pmset -a …` for the three keys. Nothing is downloaded;
  no other state is touched.
- **Posture note:** shorter `displaysleep` combined with the
  [`lockscreen-immediate`](../lockscreen-immediate) recipe means your screen locks
  the moment it sleeps when you step away — a mild *hardening*. On its own, sleep
  timing is a convenience/energy setting, not a security control.
- **Reverse it:** re-run with different values, or restore defaults with
  `sudo pmset -a displaysleep <n> disksleep <n> powernap 1` (or reset via
  System Settings → Battery / Lock Screen).
