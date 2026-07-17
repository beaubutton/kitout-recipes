# expanded-save-panels

Make macOS **Save** and **Print** dialogs open in their **expanded** form by
default — the full file browser and all print options, not the collapsed sheet.

## What it does

Writes four `NSGlobalDomain` keys via kitout's `defaults` step (per-key change
detection):

| Key | Effect |
|---|---|
| `NSNavPanelExpandedStateForSaveMode` | Save dialog opens expanded |
| `NSNavPanelExpandedStateForSaveMode2` | newer key name for the same behavior |
| `PMPrintingExpandedStateForPrint` | Print dialog opens expanded |
| `PMPrintingExpandedStateForPrint2` | newer key name for the same behavior |

Apple has renamed these keys across releases, so setting **both** the original and
the `…2` variant covers old and new AppKit. All four are booleans, so `defaults
read` renders them back as `1` and the step is honestly idempotent. No `kill` —
apps read the value each time a panel opens.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`.

## Caveats

- Only affects apps that use the **standard AppKit** Save/Print panels. Apps with
  custom dialogs (some Adobe, some Electron) ignore these keys.
- Some apps remember your **last** expanded/collapsed choice per-app and may
  override the default after you toggle it there.

## Security

None. These are user-scoped UI preferences in your own `NSGlobalDomain` — no
privilege, no network, no system files, no data touched. It only changes how a
dialog is *drawn*. Reverse any key with `defaults delete NSGlobalDomain <key>` or
by writing `false`.
