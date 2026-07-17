# default-archive

Set the default app that opens `.zip` archives — route them to Keka, The
Unarchiver, or keep Apple's Archive Utility.

## What it does

Runs `duti -s <bundle-id> public.zip-archive all`, making your chosen app the
handler for the `.zip` UTI. Like the default *terminal* (and unlike the default
*browser*), `duti` sets document-type handlers **silently** — no macOS consent
dialog. The step's `check` reads `duti -d public.zip-archive` and re-runs only
when it isn't already your app.

## Requirements

- `brew "duti"` — macOS ships no built-in CLI for setting UTI handlers.
- Your extractor installed, with its bundle id resolvable
  (`osascript -e 'id of app "Keka"'`). Apple's built-in extractor is
  `com.apple.archiveutility` and is always present.

## Adopt

1. Copy `default-archive.sh` into your config's `steps/`.
2. Set `APP` in the script to your extractor's bundle id, and change the
   matching bundle id in the step's `check`. Common ids: `com.aone.keka`,
   `cx.c3.theunarchiver`, `com.apple.archiveutility`.
3. Paste the `[[step]]` from `step.toml`.

## Caveats

- **`.zip` only.** Scope is the `public.zip-archive` UTI. `.rar`, `.7z`,
  `.tar.gz`, `.dmg`, etc. have their own UTIs and keep their existing handler;
  add them to the script (e.g. `public.tar-archive`,
  `org.7-zip.7-zip-archive`) if you want the same app to own those too.
- Archive tools differ in behavior on open (extract-in-place vs. prompt vs. show
  contents). That's the app's setting, not something this recipe controls.

## Security

Minimal for *this recipe* — it sets a user-scoped file-association preference
(LaunchServices), no privilege, no network, no system state. The relevant risk
is downstream and general to macOS: **the handler runs when you double-click a
`.zip`, and extraction writes files to disk.** A malicious archive can carry
zip-slip paths, quarantined executables, or a bundle that looks like a document.
That risk is a property of *which extractor* you choose and how it's configured
(e.g. respecting the quarantine flag), not of setting the association. Prefer an
extractor that preserves macOS quarantine on extracted items, and treat archives
from untrusted sources with your usual caution. Reverse by pointing
`public.zip-archive` back at Apple's tool:
`duti -s com.apple.archiveutility public.zip-archive all`.
