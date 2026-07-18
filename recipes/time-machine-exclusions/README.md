# time-machine-exclusions

Exclude dev-cruft directories (caches, build output) from Time Machine so your
backups stay small and fast.

## What it does

Runs `tmutil addexclusion PATH` for a user-editable list of paths, currently:

| Path | Why exclude it |
|---|---|
| `~/Library/Caches` | Regeneratable app/tool caches |
| `~/.cache` | XDG cache dir (npm, pip, cargo, etc.) |
| `~/Developer/build` | A build-output directory (edit or remove for your layout) |

The step's `check` runs `tmutil isexcluded PATH` for each configured path and
requires every one to report `[Excluded]`, so `plan`/`status` are honest and a
second `apply` is a no-op. Paths that don't exist on disk are skipped (both in
the check and the script) rather than failing.

**This only changes *what Time Machine backs up*.** It does not delete files,
does not touch any other backup mechanism (`restic`, `rclone`, Carbon Copy
Cloner, etc.), and does not disable Time Machine.

## Requirements

- macOS with Time Machine (`tmutil` ships with the OS — nothing to install).
- No sudo for the default paths — they're all user-owned under `$HOME`.
- Whatever process runs `tmutil` (Terminal, or kitout itself if run standalone)
  may need **Full Disk Access** (System Settings → Privacy & Security → Full
  Disk Access) for `tmutil addexclusion` to take effect on every path. Without
  it, `tmutil` can silently no-op on some paths — that's why this step ships
  with `on-error = "warn"`.

## Adopt

1. Copy `time-machine-exclusions.sh` into your config's `steps/`.
2. Edit the `PATHS` array in the script to match what you want excluded — and
   update the matching list in the step's `check` in `step.toml` so the two
   stay in sync (the check hardcodes the same three paths as a fast probe).
3. Paste the `[[step]]` from `step.toml`.
4. Grant Full Disk Access to Terminal (or your terminal app) if exclusions
   don't seem to stick — see Caveats.

## Caveats

- **Full Disk Access matters.** Without it, `tmutil addexclusion` can exit 0
  but not actually exclude the path on some macOS versions. If `check` keeps
  reporting pending after a successful-looking apply, this is the first thing
  to verify.
- **`check` and the script's `PATHS` array are two separate lists** — the
  format doesn't let a script step's internals drive the check, so if you add
  a path to one, add it to the other.
- Excluding a path only affects **future** backups; it does not retroactively
  remove already-backed-up copies of that path from existing Time Machine
  snapshots or reclaim their space.
- If a path doesn't exist yet (e.g. `~/Developer/build` before your first
  build), both the check and the script skip it — it'll be excluded once it
  exists and you re-apply.

## Security

**Low — this is a backup-scope preference, not a security control.**

- **What it changes:** Time Machine's exclusion list (stored in the backed-up
  volume's metadata / `com.apple.TimeMachine.exclusions.plist`-equivalent
  APIs via `tmutil`). It does not read, transmit, or delete file contents.
- **No sudo, no network.** Every default path is user-owned; nothing is
  installed or contacted.
- **Blast radius:** excluding a path you actually needed backed up (e.g. if
  you repurpose `~/Developer/build` for something that isn't disposable)
  means that data has **no Time Machine copy** going forward. Review the
  `PATHS` list against what you actually keep only-on-this-machine.
- **Reverse it:** `tmutil removeexclusion PATH` for any path, or remove the
  step and re-run `tmutil addexclusion`'s inverse manually. Re-including a
  path does not restore anything that would have been backed up during the
  excluded window — Time Machine can only back up what it's asked to going
  forward.
