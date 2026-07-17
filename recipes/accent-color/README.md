# accent-color

Set the macOS **accent color** (buttons, selected controls, checkboxes) and the
matching text-selection **highlight** — the same thing as System Settings →
Appearance → Accent color, but declarative.

## What it does

Writes three `NSGlobalDomain` keys via kitout's `defaults` step (per-key change
detection; no restart, no privilege):

| Key | Purpose |
|---|---|
| `AppleAccentColor` | which accent color, as an integer (see map below) |
| `AppleAquaColorVariant` | `1` for any colored accent; `6` only for Graphite |
| `AppleHighlightColor` | the text-selection highlight, as `"R G B Name"` floats |

**Color map** for `AppleAccentColor`:

| Value | Color | Value | Color |
|---|---|---|---|
| `0` | Red | `4` | **Blue** (shipped) |
| `1` | Orange | `5` | Purple |
| `2` | Yellow | `6` | Pink |
| `3` | Green | `-1` | Graphite |

The default macOS "Multicolor" accent is the *absence* of these keys, so this
recipe deliberately pins a specific color (Blue) rather than trying to represent
Multicolor. macOS 10.14 (Mojave)+ for accent color; the six-color palette is
macOS 11 (Big Sur)+.

No script and no `path` — pure declarative `defaults`.

## Requirements

None. Built-in macOS keys; no packages, no privilege.

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest.
2. Pick your color: set `AppleAccentColor` from the map. Keep
   `AppleAquaColorVariant = 1` for any colored accent; for **Graphite** use
   `AppleAccentColor = -1` and `AppleAquaColorVariant = 6`.
3. Optionally set `AppleHighlightColor` to match (or delete that line to keep your
   current highlight). There's nothing to copy into `steps/`.

## Caveats

- **Full effect needs a log out / log in.** New windows and most apps pick the
  accent up promptly, but the menu bar and some already-running apps only fully
  re-tint after you log back in (the recipe intentionally does **not** force a
  logout).
- `AppleHighlightColor` is a free-form `"R G B Name"` string; if it doesn't match
  the accent it just means the selection highlight differs from the accent — a
  cosmetic mismatch, not an error. Delete that key from the `write` list to leave
  the highlight alone.
- This pins one color; it can't express the "Multicolor" default (which is the
  absence of the keys). To go back to Multicolor, delete the keys (see Security).

## Security

None. These are user-scoped UI preferences in your own `NSGlobalDomain` — no
privilege, no network, no system files, no data touched. Purely which color
macOS tints its controls.

Reverse it by flipping the values, or restore the **Multicolor** default by
removing the keys:
`defaults delete -g AppleAccentColor`,
`defaults delete -g AppleAquaColorVariant`,
`defaults delete -g AppleHighlightColor` (then log out / in).
