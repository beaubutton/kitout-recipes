# default-terminal

Make your terminal the default app for shell scripts (so double-clicking an
executable, or "Open With → default", uses it instead of Terminal.app).

## What it does

Runs `duti -s <bundle-id> shell`, setting your terminal as the handler for the
`public.unix-executable` UTI. Unlike the default *browser*, this sets **silently**
— no consent dialog. The step's `check` reads `duti -d public.unix-executable`.

## Requirements

- `brew "duti"` — macOS ships no built-in CLI for setting UTI handlers.
- Your terminal must be installed (its bundle id must resolve).

## Adopt

1. Copy `default-terminal.sh` into your config's `steps/`.
2. Set `APP` in the script to your terminal's bundle id, and change the matching
   id in the step's `check`. Find an app's id with
   `osascript -e 'id of app "Ghostty"'`.
3. Paste the `[[step]]` from `step.toml`.

## Caveats

- Applies to the `public.unix-executable` UTI (shell scripts, binaries without an
  extension). It does not change how `.command` files or specific extensions open —
  those are separate UTIs.

## Security

Minimal — it sets a user-scoped file-association preference, no privilege, no
network. One thing to be aware of (a property of macOS, not this recipe): once a
terminal is the handler, **double-clicking an executable script opens it in that
terminal**, and depending on the terminal's settings that can *run* it. That's
standard macOS behavior for `public.unix-executable`; treat double-clicking
untrusted scripts with the same caution you always would. Reverse with
`duti -s com.apple.Terminal shell` (or another app).
