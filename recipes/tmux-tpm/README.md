# tmux-tpm

Install the [Tmux Plugin Manager (TPM)](https://github.com/tmux-plugins/tpm) into
`~/.tmux/plugins/tpm` — the manager that lets you declare tmux plugins in your
`~/.tmux.conf`.

## What it does

Clones the TPM repo (shallow, `--depth 1`) into `~/.tmux/plugins/tpm`. That's the
one-time bootstrap; from then on TPM manages the *other* plugins you list in your
tmux config. If an *empty* target dir is left behind (e.g. an interrupted run) the
script removes it (via `rmdir`) before cloning; a target that already has files in
it — TPM or otherwise — is left untouched, and the script aborts rather than clone
over it.

The step's `check` probes for the manager's entrypoint (`~/.tmux/plugins/tpm/tpm`),
so `plan`/`status` are honest and the clone never runs twice.

## Requirements

- `git` on PATH (macOS Command Line Tools, or `brew "git"`). Point the step's
  `needs` at whatever installs it if it isn't present.
- Network access to `github.com`.
- `tmux` itself (`brew "tmux"`) — TPM is useless without it, though this recipe
  only installs the manager.

## Adopt

1. Copy `tmux-tpm.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. Add the TPM stanza to your `~/.tmux.conf` (this recipe does **not** edit
   `~/.tmux.conf` — that file is yours to own):

   ```tmux
   set -g @plugin 'tmux-plugins/tpm'
   set -g @plugin 'tmux-plugins/tmux-sensible'
   # ... your other plugins ...
   run '~/.tmux/plugins/tpm/tpm'   # keep this line LAST
   ```
4. Reload tmux (`tmux source ~/.tmux.conf`) and press **prefix + I** (capital i) to
   install the declared plugins.

## Caveats

- **Installs the manager, not your plugins.** You still list plugins in
  `~/.tmux.conf` and press **prefix + I** to fetch them (or run
  `~/.tmux/plugins/tpm/bin/install_plugins` non-interactively).
- **The `run '…/tpm'` line must be last** in `~/.tmux.conf`, after all `@plugin`
  declarations, or plugins won't load.
- Doesn't manage TPM updates; `prefix + U` inside tmux updates plugins, and
  `git -C ~/.tmux/plugins/tpm pull` updates TPM itself.
- Uses the default `~/.tmux/plugins` path; if you set `@tpm_plugins` /
  `TMUX_PLUGIN_MANAGER_PATH` to a custom dir, adjust the clone destination and
  `check` to match.

## Security

**This clones and (later, on your keystroke) runs third-party code — the standard
TPM workflow, spelled out.**

- **Cloning is inert.** The recipe only `git clone`s the TPM repo into your home
  directory. Nothing executes at apply time.
- **Running plugins is your explicit action.** TPM and the plugins you declare are
  shell/tmux code that runs when you press **prefix + I** / reload tmux — you are
  trusting the TPM project and each `@plugin` you add. Pin plugins to repos you
  trust; review anything unfamiliar before installing, same as any dotfile plugin.
- **No privilege.** Everything lands under `~/.tmux` in your home directory; no
  `sudo`, no system files.
- **Transport trust:** the clone is HTTPS from `github.com` (TLS). Nothing is piped
  to a shell.
- **Reverse it:** `rm -rf ~/.tmux/plugins` removes TPM and all installed plugins;
  also remove the TPM lines from `~/.tmux.conf`.
