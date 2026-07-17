# pipx

Put [pipx](https://pipx.pypa.io)'s app directory (`~/.local/bin`) on your `PATH` so
CLI tools installed with `pipx install …` are runnable in a new shell.

## What it does

A `script` step that runs **`pipx ensurepath --all-shells`** — pipx's own helper that
appends the `~/.local/bin` export to your shell rc files, **including `~/.zshrc`**. The
script exits 0 fast when `~/.local/bin` is already referenced in `~/.zshrc`, so it's
idempotent; `pipx ensurepath` also dedups per rc file on its own.

**Why `--all-shells` and not a bare `pipx ensurepath`:** pipx (via the `userpath`
library) chooses which rc file to edit by sniffing its **parent process name**. When
kitout runs this script non-interactively, that parent is *bash* — so a bare
`pipx ensurepath` would write `~/.bashrc` / `~/.bash_profile` and **never** `~/.zshrc`,
leaving a zsh workstation un-fixed and this step's `~/.zshrc` check permanently pending.
`--all-shells` writes every shell's rc (zsh included), which is what makes the check
converge and a new zsh shell actually see the bin dir.

The step's `check` greps `~/.zshrc` for `~/.local/bin`, so `plan`/`status` are
honest and the script no-ops once converged.

This recipe assumes the **`pipx` binary is already installed** (see Requirements);
it fixes `PATH`, it does not install pipx.

## Requirements

- The `pipx` binary on `PATH`: `brew "pipx"` (Homebrew's pipx is the least-friction
  route on macOS). Point the step's `needs` at it.
- No privilege — pipx installs into `~/.local` and edits your own rc files.

## Adopt

1. Copy `pipx.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml`; add `needs = ["<your pipx install step>"]`.
3. `kitout apply`, then open a new shell (or `source ~/.zshrc`).
4. `pipx install <tool>` (e.g. `pipx install ruff`) and confirm the tool runs.

## Caveats

- **`--all-shells` writes every shell's rc**, not just `~/.zshrc` — it also touches
  `~/.bashrc`, `~/.profile`/`~/.bash_profile`, and (if present) fish/xonsh configs.
  That is deliberate: it is the only way to guarantee `~/.zshrc` gets the line when
  the script runs under a bash parent (see "What it does"). Each addition is deduped
  and marked by pipx, so re-runs don't stack up.
- **The check assumes `~/.zshrc` under the default `ZDOTDIR`.** If you set `ZDOTDIR`,
  pipx writes `$ZDOTDIR/.zshrc` while the check greps `$HOME/.zshrc` — they won't
  agree and the step will re-run every apply. Point the check at your real rc if so.
- **Custom `PIPX_BIN_DIR`:** the script honors `PIPX_BIN_DIR` for its check, but pipx
  *resolves* the path (expands `~`/vars, canonicalizes symlinks) before writing it. If
  your `PIPX_BIN_DIR` has symlinked or `~`/relative components, the written line may
  not match the check verbatim — set it to a plain absolute path, or update the path
  in both `step.toml`'s `check` and `pipx.sh`.
- **Homebrew's pipx already puts `~/.local/bin` on PATH** in many setups via its own
  shellenv; if so, this step is simply already-satisfied — which is the correct,
  idempotent outcome, not a failure.
- Takes effect in **new** shells — `source ~/.zshrc` for the session that applied.
- It does **not** install any pipx-managed tool — it only fixes `PATH`.

## Security

Low. No privilege, no network at apply time.

- **What it changes:** it runs `pipx ensurepath --all-shells`, which appends a `PATH`
  line for `~/.local/bin` to your own shell rc files (`~/.zshrc`, `~/.bashrc`,
  `~/.profile`/`~/.bash_profile`, and fish/xonsh configs if present). No system files,
  no sudo. Reverse by removing the pipx-marked line from each of those rc files (pipx
  prefixes its addition with a "Created by pipx" comment).
- **The tools it enables:** once `~/.local/bin` is on `PATH`, anything you later
  `pipx install` becomes directly runnable. pipx installs each tool into its own
  isolated venv from PyPI and runs its console-scripts — the normal exposure of
  installing Python CLIs; this step doesn't install any tool itself, it only makes
  the bin dir reachable.
- **Blast radius of the PATH change itself:** adding `~/.local/bin` to `PATH` means a
  binary placed there shadows one later in `PATH` — keep `~/.local/bin` under your
  control (it's your home dir) and don't let untrusted processes write to it.
