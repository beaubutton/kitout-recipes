# default-editor

Open text and source-code files in your editor (VS Code, Sublime, Zed, …) by
default, instead of TextEdit.

## What it does

Runs `duti -s <bundle-id> <UTI> editor` for the two umbrella UTIs that most
editable text conforms to:

- `public.plain-text` — `.txt`, `.md`, config files, dotfiles, and friends.
- `public.source-code` — `.py`, `.rs`, `.js`, `.sh`, and other source files.

Like the default *terminal* (and unlike the default *browser*), `duti` sets
document-type handlers **silently** — there's no macOS consent dialog. The
step's `check` reads `duti -d` for **both** managed UTIs and re-runs unless
*both* already point at your editor, so a partially-converged machine (one UTI
set, the other grabbed by another app) is correctly reported as pending.

## Requirements

- `brew "duti"` — macOS ships no built-in CLI for setting UTI handlers.
- Your editor installed, with its bundle id resolvable
  (`osascript -e 'id of app "Visual Studio Code"'`).

## Adopt

1. Copy `default-editor.sh` into your config's `steps/`.
2. Set `APP` in the script to your editor's bundle id, and change **both**
   matching bundle ids in the step's `check`. Common ids: `com.microsoft.VSCode`,
   `com.sublimetext.4`, `dev.zed.Zed`, `com.apple.TextEdit`.
3. Paste the `[[step]]` from `step.toml`.

## Caveats

- **Umbrella UTIs only.** A specific extension that declares its *own* UTI and
  handler (say `.json` → some JSON tool) overrides the `public.plain-text` /
  `public.source-code` default and is not touched here. To claim one of those,
  add its concrete UTI to the `utis` list (e.g. `public.json`) — but the two
  umbrellas already cover the large majority of plain text and code.
- The `check` probes both `public.plain-text` and `public.source-code`. If you
  add or remove UTIs in the script, update the `check` to match the exact set you
  manage so `plan`/`status` stay honest (a UTI managed by the script but absent
  from the `check` would let a partially-converged machine read as satisfied).
- `duti` writes into the LaunchServices database; the change is effective for
  new "open" actions immediately (no logout needed in practice).

## Security

Minimal — it sets user-scoped file-association preferences (LaunchServices), no
privilege, no network, no system state. The only thing to be aware of (a
property of macOS, not this recipe): after this, **double-clicking a text or
source file opens it in your editor**. That's a passive open, not execution —
opening a `.sh` in VS Code shows its contents, it does not run it. Treat opening
untrusted files with your normal caution. Reverse by pointing the same UTIs at
another app, e.g. `duti -s com.apple.TextEdit public.plain-text editor`.
