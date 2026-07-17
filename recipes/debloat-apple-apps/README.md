# debloat-apple-apps

Remove Apple's bundled iLife apps (GarageBand, iMovie) that most dev machines
never open — declaratively, with kitout's `absent` step.

## What it does

For each app, an `absent` step probes `/Applications/<App>.app` and, **only if it
exists**, runs `rm -rf` on that bundle. The probe makes it idempotent (gone → the
step is satisfied) and self-gating (a path that doesn't exist is never touched).
The recipe ships GarageBand + iMovie; add iWork (`Pages.app`, `Numbers.app`,
`Keynote.app`) or others by copying an entry.

## Requirements

- **kitout ≥ 0.4.0** (the `absent` step).
- `sudo = true` in your manifest (kitout provides `SUDO_ASKPASS`; the removals use
  `sudo -A`, which is non-interactive).

## Adopt

Paste the `[[step]]` blocks from `step.toml`. Keep only the apps you actually want
gone — this is opinionated by design. Nothing to copy into `steps/`.

## Caveats

- Only App-Store / bundled apps in the **writable** `/Applications` can be removed.
  SIP-protected system apps (Safari, Mail, …) live on the sealed system volume and
  **cannot** be removed even with sudo — such a step would just fail.
- These apps auto-update, so a future macimum update / App Store sync could
  reinstall one; re-running the step removes it again.

## Security

**This is destructive and irreversible — read before adopting.**

- **`rm -rf` deletes permanently.** No Trash, no undo. The app bundle is gone.
- **Scope is exact and probe-gated.** Each removal targets one literal
  `/Applications/<App>.app` and runs only when that exact bundle exists — a typo'd
  or empty path never matches, so it can't `rm -rf` something unintended. **Still,
  review every path before adding an entry** — `sudo rm -rf` is unforgiving.
- **Privilege:** `sudo -A rm -rf` (needs `sudo = true`). Nothing is downloaded.
- **Recovery:** these are free Apple apps — reinstall from the App Store.
- **Do not** point this at anything you can't cheaply reinstall, and never at a
  path outside `/Applications/<App>.app`.
