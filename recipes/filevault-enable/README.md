# filevault-enable

Enable **FileVault** — full-disk encryption of the startup volume.

## What it does

Runs `fdesetup enable`, Apple's CLI for turning on FileVault. The step's
`check` reads `fdesetup status` (unprivileged) for `FileVault is On`, so
`plan`/`status` are honest and the script is a fast no-op once encryption is
already enabled.

**This command is interactive by nature and cannot be fully unattended:**

- It prompts to authenticate a user (password), so it can enable that user to
  unlock the encrypted disk at boot.
- It then **prints a one-time Personal Recovery Key** to stdout — a 24-character
  key that is the *only* way to unlock the disk if the password is ever lost.
  Nothing else, including Apple, can recover it without this key (unless you
  also escrow it, e.g. to your organization's MDM or your own iCloud account via
  the Setup Assistant flow — this script does neither).

Because of that, the step ships with `on-error = "warn"` and this recipe is
meant to be run from a real interactive terminal so you can see and save the
recovery key, not folded into an unattended `apply -y` run.

## Requirements

- Any modern macOS (`fdesetup` is built in).
- `sudo = true` in your manifest — enabling FileVault needs admin. kitout
  exposes `SUDO_ASKPASS`, but note `fdesetup enable` itself still needs
  **interactive** input beyond sudo (see Caveats) — this is not a fully
  unattended step.
- A place to safely store the recovery key **before you run this** (password
  manager, printed and locked up, your organization's key-escrow system — not a
  plaintext file next to your code).

## Adopt

1. Copy `filevault-enable.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`. Keep `on-error = "warn"`.
3. Ensure your manifest has `sudo = true`.
4. Run `kitout apply` from an **interactive terminal** (not headless/CI) for
   this step. Watch the output — **it will print your recovery key once.**
   Copy it somewhere safe immediately.
5. Reboot to start encryption (FileVault encrypts in the background after the
   next restart). Confirm later with `fdesetup status`.

## Caveats

- **Never run this step unattended/non-interactively.** `fdesetup enable`
  needs a password prompt and its recovery-key output must be captured by a
  human. If run headless, expect it to hang on input or fail — that's why
  `on-error = "warn"` is set, so a failed/incomplete run here doesn't fail your
  whole `apply`.
- **Encryption starts on next reboot**, and encrypting a large disk can take
  hours in the background (the Mac is usable throughout).
- **This recipe is idempotent only in the "already On" direction** — it never
  disables FileVault, and re-running it while encryption is in-flight will
  simply see `fdesetup status` isn't yet "On" and try to enable again, which
  will report already-in-progress / fail harmlessly given `on-error = "warn"`.
- This recipe does not configure institutional recovery-key escrow (e.g. MDM).
  If your organization requires escrow, set that up separately — the personal
  recovery key this script surfaces is not automatically sent anywhere.

## Security

**Heavy — this is the single highest-impact recipe in this cookbook. Read this
before running it.**

- **What it changes:** encrypts the entire startup disk (XTS-AES-128) so data
  at rest is unreadable without the disk password or the recovery key. This is
  a foundational protection against "someone has physical possession of this
  Mac" (lost/stolen laptop, decommissioned drive).
- **The recovery key is the whole game.** `fdesetup enable` prints a **one-time**
  24-character Personal Recovery Key. If you lose both your account password
  and this key, **your data is permanently unrecoverable** — there is no
  backdoor, no Apple override. Store it immediately in a password manager or
  other durable, secure location before doing anything else.
- **Privilege used:** `sudo fdesetup enable`. No network calls; nothing is
  uploaded or escrowed anywhere by this script.
- **Availability tradeoff:** a botched power loss *during* the initial
  encryption pass is rare but riskier than encrypting an already-stable disk —
  keep the machine powered and plugged in until encryption completes
  (`fdesetup status` reports progress).
- **Reverse it:** `sudo fdesetup disable` decrypts the disk back to plaintext
  (also takes time, runs in the background). You will likely still need to
  authenticate to do this.
