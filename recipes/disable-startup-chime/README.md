# disable-startup-chime

Silence the macOS **startup chime** — the sound the Mac plays at power-on.

## What it does

Sets the NVRAM variable `StartupMute` to `%01` (muted) with `sudo nvram
StartupMute=%01`. `%00` (or clearing the variable) restores the chime. The script
reads the variable first (unprivileged) and is a no-op when it's already muted; the
step's `check` greps `nvram StartupMute` for `%01`.

This is the same setting System Settings → Sound → "Play sound on startup" toggles —
managed here declaratively.

## Requirements

- A Mac whose firmware honors `StartupMute` (all modern Apple-Silicon and recent
  Intel Macs; the T2 chip introduced the always-on chime that this mutes).
- `sudo = true` in your manifest — writing NVRAM needs admin. kitout exposes
  `SUDO_ASKPASS`; the script uses `sudo -A` so `apply -y` runs unattended.
  (Reading NVRAM is unprivileged.)

## Adopt

1. Copy `disable-startup-chime.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`.
3. Ensure your manifest has `sudo = true`.

## Caveats

- **NVRAM, not a normal file.** The setting lives in firmware variable storage. An
  **NVRAM/PRAM reset** (or, rarely, some firmware updates) clears it — re-run the
  step to restore the mute.
- Older pre-T2 Intel Macs already suppressed the chime differently; on those this is
  harmless but may be redundant.
- Takes effect at the **next** boot; it doesn't affect the current session's sound.

## Security

Low, but it does write firmware NVRAM (hence sudo) — worth stating plainly.

- **What it changes:** exactly one boolean NVRAM variable, `StartupMute`. It does
  **not** touch other NVRAM variables (boot-args, `csr-active-config`/SIP, boot
  device, etc.) — only the chime flag.
- **Not a security control.** This is a cosmetic/acoustic preference; it neither
  hardens nor weakens the machine. No auth, no network, no data.
- **Privilege used:** `sudo nvram StartupMute=%01`. Nothing is downloaded.
- **Reverse it:** `sudo nvram StartupMute=%00` (chime plays), or
  `sudo nvram -d StartupMute` to delete the variable, or re-enable via
  System Settings → Sound.
