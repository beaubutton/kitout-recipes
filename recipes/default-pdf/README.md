# default-pdf

Set the default app that opens PDFs (Preview, Skim, a browser, …).

## What it does

Runs `duti -s <bundle-id> com.adobe.pdf viewer`, making your chosen app the
handler for the `com.adobe.pdf` UTI. Like the default *terminal* (and unlike the
default *browser*), `duti` sets document-type handlers **silently** — no macOS
consent dialog. The step's `check` reads `duti -d com.adobe.pdf` and re-runs only
when it isn't already your app.

macOS's *concrete* UTI for `.pdf` files is `com.adobe.pdf` — that's the UTI
LaunchServices binds the handler to for real PDF documents. The abstract
`public.pdf` UTI conforms to it, but `duti -d` looks up the **exact** UTI you
name and does *not* walk the conformance tree: `duti -d public.pdf` reports "no
default handler" even when Preview is your PDF app. So the recipe uses
`com.adobe.pdf` in both the script and the `check` — that's where the handler
actually lives, keeping set, read, and reality consistent.

## Requirements

- `brew "duti"` — macOS ships no built-in CLI for setting UTI handlers.
- Your viewer installed, with its bundle id resolvable
  (`osascript -e 'id of app "Preview"'`).

## Adopt

1. Copy `default-pdf.sh` into your config's `steps/`.
2. Set `APP` in the script to your viewer's bundle id, and change the matching
   bundle id in the step's `check`. Common ids: `com.apple.Preview`,
   `net.sourceforge.skim-app.skim`, `com.google.Chrome`, `org.mozilla.firefox`.
3. Paste the `[[step]]` from `step.toml`.

## Caveats

- Sets the `viewer` role. If your app also wants to be the *editor* for PDFs
  (annotation, form fill), that's the same handler in practice for most readers;
  add `duti -s "$APP" com.adobe.pdf all` if you want to claim every role.
- A browser set as the PDF handler opens PDFs in a tab, not a document window —
  that's the browser's behavior, not something this recipe controls.

## Security

Minimal — it sets a user-scoped file-association preference (LaunchServices), no
privilege, no network, no system state. Opening a PDF is a passive view; note
only the general macOS caveat that PDFs can carry scripted or external-resource
content, so a malicious PDF is a risk determined by *which viewer* you pick and
how it's configured, not by this recipe. Reverse by pointing `com.adobe.pdf` at
another app, e.g. `duti -s com.apple.Preview com.adobe.pdf viewer`.
