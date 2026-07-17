# lockscreen-immediate

Require your password **immediately** when the screen locks or the screensaver
starts — no grace period where a walk-up attacker can still get in.

## What it does

Runs `sysadminctl -screenLock immediate`, which sets the "require password after
sleep or screen saver begins" delay to **0 seconds**. This is the modern,
supported mechanism: on **macOS 10.13+** the old
`defaults write com.apple.screensaver askForPassword / askForPasswordDelay` keys
moved into a sandboxed per-user container and `defaults write` no longer applies
them reliably — `sysadminctl` is what the system actually honors, which is why this
is a `script` recipe and not a `defaults` one.

The step's `check` reads `sysadminctl -screenLock status` (read-only) and is
satisfied when the delay is already immediate, so `plan`/`status` are honest and the
script no-ops once set.

## Requirements

- macOS with `sysadminctl` (built in; present on all supported macOS).
- **Your login password** — `sysadminctl` authenticates *you* to change the setting.
  This is **not** a `sudo` step (`sudo = true` won't help); it prompts for your own
  account password with `-password -`.
- No packages to install.

## Adopt

1. Copy `lockscreen-immediate.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`. It ships with `on-error = "warn"` so a
   declined/again-later password prompt doesn't fail your whole apply.
3. `kitout apply`. **First run prompts for your login password.** Verify with
   `sysadminctl -screenLock status` (expect it to report *immediate*).

## Caveats

- **First apply is interactive** — `sysadminctl -password -` blocks on a password
  prompt. In a headless/unattended run it will wait for input; because the step is
  `on-error = "warn"`, kitout warns and moves on rather than hanging the whole run
  if it can't complete. Re-run interactively to actually set it.
- This sets the *delay* to immediate; it does **not** by itself force the screen to
  lock on a schedule. Pair it with a screensaver/lock timeout (System Settings →
  Lock Screen) so the machine actually locks when idle — otherwise "immediate on
  lock" only helps once something locks it.
- The exact wording of `sysadminctl -screenLock status` has varied across macOS
  releases; the check matches the "immediate"/"0 seconds" forms. If a future macOS
  changes the wording, the check may read as pending even when set — harmless (the
  script would just re-affirm it), but worth knowing.

## Security

**This is a hardening — it shrinks an attacker's walk-up window to zero.**

- **What it fixes.** By default macOS can allow a grace period (e.g. "require
  password 5 seconds / 1 minute after sleep begins") during which anyone who walks
  up can dismiss the lock without credentials. Setting it to *immediate* removes
  that window: the moment the screen locks, the password is required.
- **It only tightens.** The change makes access *harder*, never easier — there's no
  way this setting grants anyone new access. Worst case for usability is you type
  your password a little more often.
- **Privilege / auth.** It uses `sysadminctl`, which authenticates you with your
  **login password** (prompted interactively via `-password -`, so the password is
  never placed on the command line or in shell history / the process table). It is
  not `sudo`; it changes a per-user security preference for the current account.
- **No network, nothing downloaded.** Purely a local security-preference change.
- **Reverse it.** `sysadminctl -screenLock off` (removes the requirement) or
  `sysadminctl -screenLock <seconds>` to restore a grace delay. Both re-prompt for
  your password.
