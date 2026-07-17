# dock-items

Curate the macOS Dock — pin the apps you want, remove the ones you don't — with
[`dockutil`](https://github.com/kcrawford/dockutil).

## What it does

Drives two lists in `dock-items.sh`:

- **ADD** — `label => /path/to/App.app` pairs that must be *present*. Each is added
  (by path) only if its label isn't already in the Dock **and** the `.app` exists.
- **REMOVE** — labels that must be *absent*. Each is removed only if present.

Membership is tested against `dockutil --list` (column 1, the label), so the script
is idempotent: it computes the delta, applies only what's needed, and restarts the
Dock **once** (via `killall Dock`) — and only if something actually changed.

The step's `check` mirrors this: it passes when the sample "must-have" (VS Code) is
present and the sample "must-not-have" (Music) is gone. Edit the lists in the script
and the labels in the `check` together.

The shipped example pins **Visual Studio Code** and removes Apple's
**Music / TV / Podcasts / News** — adjust to taste.

## Requirements

- `dockutil` (macOS: `brew "dockutil"`). Point the step's `needs` at whatever
  installs it.
- No privilege — the Dock is per-user; everything runs as you.

## Adopt

1. Copy `dock-items.sh` into your config's `steps/`.
2. Edit `ADD_LABELS`/`ADD_PATHS` and `REMOVE_LABELS`. The **label** is what
   `dockutil --list` prints in column 1 (usually the app's display name — run
   `dockutil --list` to see yours).
3. Update the two app names in the `check` to a must-have / must-not-have of yours.
4. Paste the `[[step]]` from `step.toml`; add `needs = ["<dockutil step id>"]` if
   dockutil is installed by an earlier step.

## Caveats

- **Labels, not paths, for removal.** `dockutil --remove` matches the label; if two
  Dock items share a label, dockutil removes the first. Check `dockutil --list`.
- The shipped `check` only verifies the *two sample* apps, not your whole list. It's
  a representative probe, not a full reconciliation — if you want a stricter one,
  extend the `check` to grep every label you manage.
- Adding an app that isn't installed is skipped (with a note), not an error, so the
  step doesn't fail on a machine where that app hasn't landed yet.
- The Dock restart (`killall Dock`) briefly flashes the Dock — cosmetic.
- dockutil's CLI has changed flags across major versions; this uses the stable
  `--add`/`--remove`/`--list`/`--no-restart` surface.

## Security

Low. It rearranges **your own** Dock — a per-user UI preference stored in
`~/Library/Preferences/com.apple.dock.plist`. No privilege, no network, and it does
**not** install, launch, or delete any application — only which icons appear in the
Dock. Removing an item from the Dock does **not** uninstall the app; it just unpins
it. Reverse any change by editing the lists and re-applying, or reset the Dock
entirely with `defaults delete com.apple.dock; killall Dock`.
