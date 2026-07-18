# auto-security-updates

Enable automatic installation of Apple's **security** updates — without turning
on automatic installation of major macOS version upgrades.

## What it does

Runs `softwareupdate --schedule on`, then writes four keys in the
`com.apple.SoftwareUpdate` system preference domain:

| Key | Value | Meaning |
|---|---|---|
| `AutomaticCheckEnabled` | `true` | periodically check for updates |
| `AutomaticDownload` | `true` | download updates in the background once found |
| `ConfigDataInstall` | `true` | auto-install system data files (e.g. Gatekeeper/XProtect rule updates) |
| `CriticalUpdateInstall` | `true` | auto-install Security Response / critical security updates |

These are the same four toggles under System Settings → General → Software
Update → the ⓘ next to "Automatic updates". The step's `check` reads all four
keys with `defaults read` (unprivileged), so `plan`/`status` are honest and the
script is a fast no-op once converged.

**What this deliberately does NOT do:** it never touches
`AutomaticallyInstallMacOSUpdates`, the key that governs auto-installing major
macOS *version* upgrades (e.g. macOS 15 → 16). Security patches and OS upgrades
are separate settings on purpose — this recipe only turns on the former.

## Requirements

- Any modern macOS (the `com.apple.SoftwareUpdate` domain and
  `softwareupdate --schedule` have shipped for many releases).
- `sudo = true` in your manifest — writing the system preference domain and
  running `softwareupdate --schedule on` both need admin. kitout exposes
  `SUDO_ASKPASS`; the script uses `sudo -A` so `apply -y` runs unattended.
  (Reading the keys is unprivileged; only the *write* calls escalate.)

## Adopt

1. Copy `auto-security-updates.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`.
3. Ensure your manifest has `sudo = true`.

## Caveats

- Some Apple update categories still land via the normal Software Update
  mechanism and may still show a notification even when auto-install is on —
  this recipe maximizes automation, but Apple occasionally holds back an update
  that needs a restart until you're ready (or bundles it with a visible prompt).
- Does not enable automatic **major OS upgrade** installs — see above. If you
  *do* want that too, add a separate
  `defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true`
  yourself (deliberately not bundled here).
- Writing `/Library/Preferences/com.apple.SoftwareUpdate` while `cfprefsd` has it
  cached can occasionally need a `killall cfprefsd` or a login to be reflected in
  System Settings' UI, even though `defaults read` shows the new value
  immediately.

## Security

**This raises your security posture — it has no meaningful downside blast radius.**

- **What it changes:** four preferences in a system-wide (root-owned)
  preference domain, plus the software-update scheduler flag. It does not
  install anything itself beyond what Apple's update mechanism would install
  anyway; it just removes the "wait for you to click install" step for
  patches classified as security-critical.
- **Blast radius:** system-wide (affects all users on the Mac), but strictly
  limited to *when* Apple-signed updates install, not *what* gets installed.
  Nothing here fetches or executes third-party code — the updates still flow
  through Apple's normal signed-update pipeline.
- **Privilege used:** `sudo softwareupdate --schedule on` and
  `sudo defaults write` against `/Library/Preferences/com.apple.SoftwareUpdate`.
  No network calls originate from this recipe itself (they come later, from
  macOS's own updater, on its own schedule).
- **Reverse it:** set the keys back to `false`
  (`sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate
  AutomaticCheckEnabled -bool false`, and similarly for the other three) and/or
  `sudo softwareupdate --schedule off`.
