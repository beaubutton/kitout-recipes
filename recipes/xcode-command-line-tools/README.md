# xcode-command-line-tools

Ensure the **Xcode Command Line Tools** — `clang`, `make`, `git`, system
headers, the base compiler toolchain most other dev tooling assumes — are
installed.

## What it does

Checks `xcode-select -p` (prints the active developer directory, non-zero if
the CLTs aren't installed). If missing, it tries the well-known **unattended
`softwareupdate` trick** first:

1. `touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress` — a
   sentinel that makes Apple's software-update service list the CLTs as an
   available update.
2. `softwareupdate --list` and pick the `Command Line Tools` label.
3. `sudo softwareupdate --install "<label>" --verbose` — installs headlessly,
   no GUI.
4. Remove the sentinel.

If that path doesn't turn up a label (e.g. a macOS version where Apple changed
the mechanism, or no `sudo` available), it falls back to
`xcode-select --install`, which pops Apple's normal **GUI** installer dialog —
not scriptable to completion; you click through it yourself.

Idempotent either way: a converged machine (`xcode-select -p` already
succeeds) exits immediately without touching `softwareupdate` or `sudo` at all.

## Requirements

- macOS with `softwareupdate` and `xcode-select` (i.e., any supported macOS).
- **`sudo = true`** in your manifest for the unattended path — kitout exposes
  `SUDO_ASKPASS`; the script uses `sudo -A` so `apply -y` can run it
  unattended. Without sudo available, the script still runs but the
  `softwareupdate --install` call will fail and it falls through to the GUI
  path.
- A **large download** (roughly 1–2 GB depending on the macOS version) and
  network access to Apple's software update servers.

## Adopt

1. Copy `xcode-command-line-tools.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`.
3. Ensure your manifest has `sudo = true` if you want the unattended path.
4. This is commonly a base dependency for other tooling (Homebrew itself
   requires the CLTs, as do most compiled formulae) — point other steps'
   `needs` at this step's id if they assume a compiler is present.

## Caveats

- **`on-error = "warn"`**: this step is GUI-gated in the fallback case and
  always a large, sometimes slow download, so a failure here (network hiccup,
  Apple changing the `softwareupdate` label format again, the GUI installer
  needing a click) warns instead of failing your whole `apply`.
- **The GUI fallback cannot be driven to completion by kitout** (or any
  script) — if it's reached, `apply` will report success for *starting* the
  install, but you still need to click through Apple's dialog yourself. The
  step's `check` will keep reporting pending until you do.
- Apple has changed the exact `softwareupdate --list` label format and the
  sentinel-file trick's reliability across macOS releases before; if the
  unattended path silently stops working on a future OS version, the
  fallback still gets you there via the GUI.
- Running this on a machine that already has **Xcode.app** (not just the
  CLTs) is a no-op either way — `xcode-select -p` succeeds once either is
  present.

## Security

- **What it changes:** installs Apple's compiler toolchain and SDK headers —
  a substantial, trusted-publisher (Apple, via `softwareupdate`) system
  package. It does not modify any of your files or app configuration.
- **Privilege:** the unattended path needs `sudo` only for `softwareupdate
  --install`. The sentinel file lives in world-writable `/tmp`, so it is
  created and removed without privilege (sudo is only a fallback). Reading
  state (`xcode-select -p`, `softwareupdate --list`) is unprivileged.
- **Network:** the unattended path downloads the CLT package from Apple's
  software update infrastructure over HTTPS — the same channel and trust
  boundary as any macOS system update. The GUI fallback does the same via
  Apple's own installer UI.
- **Size:** a large one-time download (order of a gigabyte); not something
  you want to trigger repeatedly or on a metered connection.
- **Reverse it:** there's no first-class "uninstall" from Apple; the common
  approach is `sudo rm -rf /Library/Developer/CommandLineTools` (removes the
  tools; a subsequent `xcode-select --install` or this step reinstalls them).
