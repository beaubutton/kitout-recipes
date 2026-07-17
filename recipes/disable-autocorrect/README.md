# disable-autocorrect

Turn off macOS's "smart" text substitutions — the ones that mangle code snippets,
paths, and terminal-adjacent typing: curly quotes, auto em-dash, auto-capitalize,
autocorrect, and double-space-to-period.

## What it does

Writes five `NSGlobalDomain` keys (all `false`) via kitout's `defaults` step
(per-key change detection):

| Key | Turns off |
|---|---|
| `NSAutomaticQuoteSubstitutionEnabled` | `"` → curly "smart" quotes |
| `NSAutomaticDashSubstitutionEnabled` | `--` → em-dash |
| `NSAutomaticCapitalizationEnabled` | auto-capitalizing the first letter |
| `NSAutomaticSpellingCorrectionEnabled` | autocorrect (the red-underline replace) |
| `NSAutomaticPeriodSubstitutionEnabled` | double-space → `. ` |

All booleans, so `defaults read` renders them back as `0` and the step is honestly
idempotent. No `kill` — apps read these when they launch a text view.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Nothing to copy into
`steps/`. Keep only the substitutions you actually want off.

## Caveats

- **Takes effect on next app launch.** Already-open apps keep their current
  behavior until relaunched (or log out / in).
- Only affects apps that use the **system text engine** (TextEdit, Notes, Mail,
  most native fields). Apps with their own editors — VS Code, most browsers'
  text areas, terminals — were never governed by these keys anyway.
- This is the **global default**. Some apps expose their own Edit ▸ Substitutions
  toggle that can re-enable a substitution per-app.

## Security

None. These are user-scoped input preferences in your own `NSGlobalDomain` — no
privilege, no network, no system files, no data touched. Reverse any key with
`defaults delete NSGlobalDomain <key>` (restores the macOS default) or by writing
`true`.
