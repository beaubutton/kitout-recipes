# default-browser

Set your default web browser.

## What it does

Runs `defaultbrowser <id>`, which registers your browser as the handler for the
`http`/`https` URL schemes. The step's `check` reads `defaultbrowser`'s listing
(it marks the current default with `* `), so `plan`/`status` are honest.

## Requirements

- `brew "defaultbrowser"` — macOS ships no built-in CLI for this.
- Point the step's `needs` at whatever installs it if it isn't already present.

## Adopt

1. Copy `default-browser.sh` into your config's `steps/`.
2. Set `BROWSER` in the script to your browser's id (run `defaultbrowser` to list —
   `edge`, `chrome`, `safari`, `firefox`, `brave`, …). **Also** change the `edge` in
   the step's `check` to match.
3. Paste the `[[step]]` from `step.toml`.

## Caveats

- **GUI-gated.** macOS pops a "Use '<browser>' as your default browser?" dialog you
  must click. No API or tool bypasses it — so the step is `on-error = "warn"`, and
  on a headless/unattended run it warns instead of blocking the DAG.
- The dialog appears once per change; after that the step is satisfied and silent.

## Security

None of consequence — it sets a user preference. The consent dialog is macOS's
**anti-hijack protection** (so malware can't silently seize your browser), which is
a feature, not an obstacle: this recipe works *with* it. No privilege, no network.
Reverse it by setting a different default (or via System Settings → Desktop & Dock).
