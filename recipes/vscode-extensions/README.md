# vscode-extensions

Install a **user-editable list of VS Code extensions**, idempotently.

## What it does

Loops over an `EXTS` array in `vscode-extensions.sh` — shipped with three common
starters (`editorconfig.editorconfig`, `dbaeumer.vscode-eslint`,
`esbenp.prettier-vscode`) — and for each one:

```sh
code --list-extensions | grep -qix "$ext" || code --install-extension "$ext"
```

i.e. it only calls `code --install-extension` for extensions that aren't already
present, so a second run is a fast no-op once everything's installed.

The step's `check` only confirms the `code` CLI is on `PATH` — it's a
prerequisite gate, not a full convergence check (kitout doesn't compare list
contents), so the script re-runs its own idempotent loop every `apply`; with all
extensions already present that's a handful of `code --list-extensions` calls
and nothing else.

## Requirements

- The **`code` CLI on `PATH`**. VS Code doesn't add this automatically: open VS
  Code, `Cmd+Shift+P` → **"Shell Command: Install 'code' command in PATH"**.
- VS Code itself, obviously.

## Adopt

1. Copy `vscode-extensions.sh` into your config's `steps/`.
2. Edit the `EXTS` array to your own list (find ids on each extension's
   marketplace page, or run `code --list-extensions` on a machine that already
   has what you want).
3. Paste the `[[step]]` from `step.toml`.
4. Add `needs = ["<your VS Code step id>"]` if VS Code isn't already installed
   earlier in the DAG.

## Caveats

- **`on-error = "warn"`**: if `code` isn't on `PATH` yet (VS Code installed but
  the shell command never set up), the step warns and moves on instead of
  failing the whole apply — re-run once you've installed the CLI.
- Each `code --install-extension` call talks to the Marketplace and can take a
  few seconds per extension; a first run with a long list isn't instant.
- This only **adds** extensions from the list — it never removes one you've
  installed outside the list, and it doesn't pin versions or auto-update
  existing ones.

## Security

Extensions are **third-party code that runs inside your editor**, with access to
your open workspaces and often the ability to run their own processes (language
servers, linters, formatters). This script installs exactly the extensions you
put in `EXTS` — nothing is fetched or chosen automatically beyond that list.
**Only add extension ids you actually trust**; treat the shipped three as a
starting point, not an endorsement to add more without checking. No privilege
escalation, no system files touched — extensions install to
`~/.vscode/extensions`. Reverse with `code --uninstall-extension <id>` or by
removing it from the list and re-running (removal isn't automatic — see
Caveats).
