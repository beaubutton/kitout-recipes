# remote-login-off

Ensure **Remote Login** (macOS's built-in SSH server, `sshd`) is **off** —
nobody can SSH into this Mac.

## What it does

Runs `systemsetup -setremotelogin -f off`, the supported CLI for the same
toggle as System Settings → General → Sharing → Remote Login. The `-f` flag
skips the interactive "are you sure" confirmation. The step's `check` reads
`sudo -n systemsetup -getremotelogin` and is satisfied when it reports `Off`.

Why `sudo -n` in the check? Unlike `spctl`/`fdesetup`, `systemsetup` requires
root even to *read* `-getremotelogin` — an unprivileged probe only ever gets
"You need administrator access...", so it could never see `Off`. Reading through
`sudo -n` (non-interactive; uses kitout's cached sudo timestamp during `apply`,
never prompts) lets the check see the real state, so during `apply` the script
fast-exits and is idempotent once converged. A standalone `plan`/`status` does
**not** bootstrap sudo, so it may still show this step as pending even when
Remote Login is already off — that's the unavoidable cost of a setting macOS
only lets root read, and `on-error = "warn"` keeps it from failing your run.

**This is the "off" direction only.** This recipe never turns Remote Login on;
if you actually want inbound SSH, don't adopt it (or write the inverse
yourself: `systemsetup -setremotelogin on`).

## Requirements

- Any modern macOS (`systemsetup` is built in).
- `sudo = true` in your manifest — both reading and writing this setting
  typically need admin on modern macOS. kitout exposes `SUDO_ASKPASS`; the
  script uses `sudo -A` so `apply -y` runs unattended.
- **Full Disk Access** for whatever process invokes `systemsetup` (Terminal,
  or the agent/shell kitout runs under) — System Settings → Privacy &
  Security → Full Disk Access. Recent macOS gates `systemsetup`'s
  remote-login calls behind this; without it the command can silently no-op
  or error even when run under `sudo`.

## Adopt

1. Copy `remote-login-off.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`. Keep `on-error = "warn"`.
3. Ensure your manifest has `sudo = true`, and grant Full Disk Access to the
   terminal/process running `kitout apply` if the step warns instead of
   converging.

## Caveats

- **Do not adopt this if you SSH into this machine remotely** (e.g. as a
  headless server, a machine you administer over Tailscale/SSH, or anything
  you manage from another box) — this recipe closes that access. If this Mac
  is your only way in, you will lose remote access until you're physically at
  the keyboard (or use another remote-control tool, e.g. Screen Sharing, that
  you've deliberately kept available).
- **May need Full Disk Access + sudo together** — recent macOS versions gate
  even *reading* `-getremotelogin` behind privacy protections in some
  configurations. If the step keeps warning instead of converging, check Full
  Disk Access first.
- `on-error = "warn"` means a permissions problem here warns rather than
  failing your whole `apply` — but it also means you should actually look at
  the warning rather than assume it worked.

## Security

**This raises your security posture, in exactly one direction, with one
important tradeoff to know before adopting.**

- **What it changes:** disables macOS's built-in OpenSSH server (`sshd`) from
  accepting inbound connections. With Remote Login off, nothing can SSH into
  this Mac — full stop, regardless of what keys or passwords exist.
- **Blast radius:** system-wide (affects all users), but narrowly scoped to
  the SSH *server* role. It does not touch this Mac's ability to act as an SSH
  *client* (i.e., you can still SSH out to other machines fine) or any other
  service (Screen Sharing, file sharing, etc. are separate toggles).
- **The one real risk: locking yourself out remotely.** If you or your tooling
  currently depends on `ssh this-mac` from elsewhere, running this recipe cuts
  that off immediately, with no grace period. Read the Caveats above before
  adopting.
- **Privilege used:** `sudo systemsetup -setremotelogin -f off`. No network
  calls, nothing downloaded, no data removed — this only closes a listening
  service.
- **Reverse it:** `sudo systemsetup -setremotelogin on` (or the equivalent
  toggle in System Settings → General → Sharing → Remote Login).
