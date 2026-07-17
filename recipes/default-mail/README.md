# default-mail

Set your default **mailto:** client — the app that opens when you click an email
link (Mail, Outlook, Spark, …).

## What it does

Runs `duti -s <bundle-id> mailto`, registering your mail app as the handler for
the `mailto:` URL scheme. Unlike the document-type recipes (PDF, images,
archives) which set **silently**, the `mailto:` default is one macOS *guards*:
changing it can pop a one-time consent dialog you must click — the same
anti-hijack protection as the default browser. No tool can suppress that dialog,
so the step is `on-error = "warn"`. The step's `check` reads `duti -d mailto` and
re-runs only when it isn't already your app.

## Requirements

- `brew "duti"` — macOS ships no built-in CLI for setting scheme handlers.
- Your mail app installed, with its bundle id resolvable
  (`osascript -e 'id of app "Mail"'`).

## Adopt

1. Copy `default-mail.sh` into your config's `steps/`.
2. Set `APP` in the script to your mail app's bundle id, and change the matching
   bundle id in the step's `check`. Common ids: `com.apple.mail`,
   `com.microsoft.Outlook`, `com.readdle.smartemail-Mac` (Spark).
3. Paste the `[[step]]` from `step.toml`.
4. Run `kitout apply`, then **confirm the macOS dialog if it appears** and
   re-check with `duti -d mailto`.

## Caveats

- **GUI-gated.** macOS may show a "Change your default email reader?" dialog you
  must click; it can't be automated, which is why the step is `on-error = "warn"`
  — a warn (not a failure) if the change doesn't land unattended.
- Some builds of macOS accept the `mailto:` change without a prompt; whether the
  dialog appears depends on the OS version and whether the app was seen before.
  The `check` is the source of truth either way.
- Sets only the `mailto:` scheme. It does not change what opens `.eml` message
  files (that's the `com.apple.mail.email` UTI — a separate association).

## Security

Low blast radius — it sets a user-scoped default (LaunchServices) for one URL
scheme, no privilege, no network, no system state. The macOS consent dialog
exists precisely *because* the default mail client is a hijack target (a rogue
app rerouting your outbound mail links), so the prompt is a feature: you're
approving the change interactively. This recipe only points `mailto:` at an app
**you** name. Reverse by pointing it at another app, e.g.
`duti -s com.apple.mail mailto`.
