# dark-mode-auto

Set the macOS system appearance to **Auto** (light by day, dark by night, on the
system's sunrise/sunset schedule) — or force plain Dark / Light.

## What it does

Runs `dark-mode-auto.sh`, which converges `NSGlobalDomain` (`-g`) to one of three
states via the `MODE` env var (default `auto`):

| `MODE` | Keys written | Result |
|---|---|---|
| `auto` (default) | `AppleInterfaceStyleSwitchesAutomatically = true`, and **removes** `AppleInterfaceStyle` | appearance follows the day/night schedule |
| `dark` | `AppleInterfaceStyle = Dark`, switch-automatically off | always Dark |
| `light` | removes `AppleInterfaceStyle`, switch-automatically off | always Light |

**Why a script and not a `defaults` step:** "Auto" is not one key — it needs
`AppleInterfaceStyleSwitchesAutomatically = 1` *and* the **absence** of
`AppleInterfaceStyle`, and kitout's `defaults` step only writes (it can't delete a
key).

For the **fixed** `dark`/`light` modes the script also nudges the running UI with a
one-line `osascript` (System Events → appearance preferences → *dark mode*),
because a raw `defaults` write doesn't reliably repaint already-open apps. **Auto
mode gets no such nudge:** the only AppleScript primitive is the `dark mode`
boolean, which selects a *fixed* Light or Dark and would clear the "switch
automatically" flag — so for `auto` the `defaults` write is the whole change and
open apps repaint to the schedule after a relaunch / next login. macOS 10.14
(Mojave)+; Auto mode needs macOS 10.15 (Catalina)+.

The step's `check` probes `AppleInterfaceStyleSwitchesAutomatically`, so `plan`/
`status` are honest and the script is a fast no-op once converged.

## Requirements

None. Built-in macOS keys and `osascript`; no packages, no privilege.

## Adopt

1. Copy `dark-mode-auto.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. For forced Dark instead of Auto, set `MODE=dark` (run the script with
   `MODE=dark`, or add an `env`-setting wrapper) **and** swap the `check` in
   `step.toml` to the Dark probe noted in its comment — otherwise `plan` will keep
   showing the step as pending.

## Caveats

- **GUI-gated live switch (`dark`/`light` only).** For the fixed modes the
  `osascript` line that repaints open apps can trigger a one-time **Automation
  consent** prompt ("Terminal wants to control System Events"). If you decline, the
  appearance still changes — just on the next login/relaunch rather than instantly.
  The step uses `on-error = "warn"` so a declined prompt never fails your apply.
- **Auto mode has no live nudge.** There is no AppleScript command that selects
  "Auto" (`set dark mode` only picks a fixed Light/Dark and would *cancel* Auto),
  so `MODE=auto` writes the keys and lets open apps catch up on relaunch / next
  login. The scheduled switching itself is immediate; only the currently-open
  windows may lag.
- The `check` in `step.toml` is written for `MODE=auto`. If you switch to `dark`
  or `light`, update the `check` to match (see the comment in `step.toml`),
  otherwise the step never reports satisfied.
- Some system chrome (menu bar, wallpaper-tinted surfaces) fully settles after a
  log out / log in.

## Security

None — this is a per-user UI preference. It writes appearance keys in your own
`NSGlobalDomain` (no privilege, no network, no system files) and, for the fixed
`dark`/`light` modes only, best-effort sends one AppleScript command to **System
Events** to repaint the live UI. (`MODE=auto`, the default, sends no AppleScript
at all.)

- **Automation scope:** in `dark`/`light` mode the `osascript` line asks the local
  **System Events** process to set dark mode on/off — nothing else. The consent
  prompt it can raise is macOS's normal Automation gate; granting it lets *this
  terminal* script toggle appearance, not control anything remote. It is never
  fatal (`on-error = "warn"`, and the call is wrapped so failure is ignored).
- **Reverse it:** run with `MODE=light` (or `MODE=dark`), or from System Settings
  → Appearance. To wipe the keys entirely:
  `defaults delete -g AppleInterfaceStyle` and
  `defaults delete -g AppleInterfaceStyleSwitchesAutomatically`.
