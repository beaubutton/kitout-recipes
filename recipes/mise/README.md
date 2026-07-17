# mise

Activate [mise](https://mise.jdx.dev) — the polyglot runtime version manager
(Python, Node, Ruby, Go, …, plus per-project tool + env management) — in your
interactive shell.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:mise >>>` … `# <<< recipes:mise <<<`) containing:

```sh
eval "$(mise activate zsh)"
```

`mise activate` prepends mise's shim/shims directory to `PATH` and installs a
shell hook so that entering a directory with a `mise.toml` (or `.tool-versions`)
switches tool versions automatically. Everything outside the markers stays yours;
kitout only rewrites the block. No script.

This recipe installs the *shell hook*, not the mise binary — see Requirements.

## Requirements

- The `mise` binary on `PATH`: `brew "mise"` (or mise's official installer).
  Point the step's `needs` at whatever installs it so the hook lands after it.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Add
`needs = ["<your mise install step>"]`. Nothing to copy into `steps/`. Open a new
shell (or `source ~/.zshrc`) to pick it up, then `mise doctor` to confirm.

## Caveats

- **zsh only** as written. For bash, change the block to
  `eval "$(mise activate bash)"` and target `~/.bashrc`; for fish, use fish syntax
  in `~/.config/fish/config.fish`.
- Applies to **new** shells — the shell that ran `apply` won't have it until you
  `source ~/.zshrc` or open a new terminal.
- `mise activate` uses shims/hooks; if you previously added mise to `PATH` by hand,
  remove that so you don't double-activate.

## Security

Low. It edits a marked block in your own `~/.zshrc` — no privilege, no network at
apply time, and it never touches the rest of the file.

The line it adds runs `eval "$(mise activate zsh)"` **every time you open a shell**,
executing whatever the on-PATH `mise` binary emits — so the trust boundary is the
mise binary itself (install it from a source you trust; that's the Requirements
step's concern, not this one). Separately, once active, mise reads per-project
`mise.toml`/`.tool-versions` and can be configured to auto-run project hooks and
install tools; treat entering an untrusted repo the same as running its build.
Reverse by deleting the block (or removing the recipe and re-applying).
