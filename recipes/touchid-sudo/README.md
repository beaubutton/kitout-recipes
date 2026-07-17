# touchid-sudo

Authenticate `sudo` with **Touch ID** (and a paired Apple Watch, if you use one)
instead of typing your password.

## What it does

Adds a single line — `auth sufficient pam_tid.so` — to **`/etc/pam.d/sudo_local`**.
On **macOS 14 (Sonoma) and later**, the `sudo` PAM stack includes `sudo_local`, so
this is the Apple-intended, **upgrade-safe** place to put it: it survives OS updates.
(Editing `/etc/pam.d/sudo` directly also works but gets reset on every macOS upgrade.)

The step's `check` greps for an active `pam_tid.so` line, so `plan`/`status` are
honest and the script never double-appends.

## Requirements

- **macOS 14+.** On older macOS there's no `sudo_local`; you'd edit `/etc/pam.d/sudo`
  directly (not upgrade-safe) — this recipe deliberately doesn't.
- A Mac with a Touch ID sensor (or a paired Apple Watch).
- `sudo = true` in your manifest (kitout collects the password once and exposes
  `SUDO_ASKPASS` so the script's `sudo` runs unattended).

## Adopt

1. Copy `touchid-sudo.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`.
3. Ensure your manifest has `sudo = true`.
4. Open a **new** terminal after applying, then `sudo -v` to see the Touch ID prompt.

## Caveats

- Takes effect in **new** shell sessions, not the one that ran the apply.
- Terminal apps must have Touch ID access; most do. `tmux`/`screen` can interfere
  with the prompt — Apple ships `pam_reattach` for that (out of scope here).

## Security

**This modifies how `sudo` authenticates — read before adopting.**

- **What it grants:** any fingerprint enrolled in Touch ID (or your paired,
  unlocked Apple Watch) can now authorize `sudo`. Only *your* enrolled prints work;
  it does not add anyone else.
- **`sufficient`, not `required`:** Touch ID *success* grants `sudo` without the
  password; Touch ID *failure or absence* falls through to the normal password
  prompt — so you can never lock yourself out.
- **Does NOT weaken remote access:** `pam_tid.so` needs local biometric hardware,
  so `sudo` **over SSH still requires your password**. Biometric auth applies only
  at the physical machine.
- **Net effect on posture:** generally a *hardening* — a fingerprint isn't
  keylogged or shoulder-surfed the way a typed password is. The tradeoff is that
  physical presence + your fingerprint (or an unlocked paired Watch) now suffices
  for privilege escalation; on a shared or unattended machine, weigh that.
- **Privilege used:** one `sudo tee -a` to append a root-owned file under
  `/etc/pam.d`. Nothing is downloaded; nothing else is touched.
- **Reverse it:** remove the `pam_tid.so` line from `/etc/pam.d/sudo_local` (or
  delete the file).
