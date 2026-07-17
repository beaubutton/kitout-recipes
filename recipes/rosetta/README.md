# rosetta

Install **Rosetta 2** on Apple Silicon so x86_64-only apps and tools run.

## What it does

On `arm64`, runs `softwareupdate --install-rosetta --agree-to-license` when
`/Library/Apple/usr/share/rosetta` is absent. On Intel Macs it's a clean no-op. The
step's `check` treats "not Apple Silicon" or "Rosetta present" as satisfied, so it
never re-runs.

## Requirements

- Apple Silicon (does nothing on Intel).
- No packages, no sudo (`softwareupdate` carries the install entitlement).

## Adopt

1. Copy `rosetta.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`.

## Caveats

- First install pulls a package from Apple — needs network, takes a moment.
- Some apps (Docker images, older Homebrew bottles, certain Electron builds) require
  Rosetta; installing it up front avoids a mid-work prompt.

## Security

Low. It installs **Apple-signed system software** (Rosetta 2) via Apple's own
`softwareupdate`. The one thing to note is `--agree-to-license`: it **accepts
Apple's software license agreement non-interactively** on your behalf — that's the
whole point (unattended install), but you're agreeing to Apple's SLA
programmatically. No third-party code, no sudo, and it's removable (`softwareupdate
--install-rosetta` has no uninstall, but Rosetta is inert unless an x86 binary runs).
