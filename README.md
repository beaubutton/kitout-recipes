# kitout-recipes

A cookbook of reusable **[kitout](https://github.com/beaubutton/kitout) steps** for
common macOS workstation tasks — the things without a dedicated step type, so people
keep rewriting the same `defaultbrowser`/`duti`/`defaults` snippets from scratch.

Each recipe is **browse-and-copy**: read it, copy it into your own config, own it.
kitout never downloads or runs anything from here — no fetch command, no remote
execution. Every recipe ships with docs, a test, and an honest **Security** note.

> New to kitout? A recipe is a step you paste into your `kitout.toml` — see the
> [manifest reference](https://github.com/beaubutton/kitout/blob/main/docs/manifest.md).

## How to use a recipe

1. Open `recipes/<name>/` and read its `README.md` — especially **Requirements** and **Security**.
2. If it's a `script` recipe, copy `<name>.sh` into your config's `steps/` dir.
3. Paste the `[[step]]` from `step.toml` into your manifest; adjust `id`/`needs` and any
   hardcoded value (which browser, which name) to taste.
4. `kitout plan` to preview, `kitout apply` to converge.

## Recipes

| Recipe | Step | What it does |
|---|---|---|
| [`1password-ssh-agent`](recipes/1password-ssh-agent) | `block-in-file` | Route SSH authentication through the **1Password SSH agent** so your key |
| [`accent-color`](recipes/accent-color) | `defaults` | Set the macOS **accent color** (buttons, selected controls, checkboxes)  |
| [`agents-md-global`](recipes/agents-md-global) | `block-in-file` | Seed a **global `AGENTS.md`** — the house rules every coding agent reads |
| [`app-firewall`](recipes/app-firewall) | `script` | Enable macOS's built-in **application firewall** and **stealth mode**. |
| [`atuin`](recipes/atuin) | `block-in-file` | Initialize [Atuin](https://atuin.sh) — a SQLite-backed replacement for y |
| [`aws-profile`](recipes/aws-profile) | `block-in-file` | Scaffold a named AWS profile in `~/.aws/config` — region, output format, |
| [`bun`](recipes/bun) | `command-if-missing` | Install [bun](https://bun.sh) — the fast, all-in-one JavaScript/TypeScri |
| [`caps-to-control`](recipes/caps-to-control) | `script` | Remap **Caps Lock → Control**, and make it stick across reboots. |
| [`claude-statusline`](recipes/claude-statusline) | `json-merge` | Seed a **Claude Code status line** — model, context-window usage, and cu |
| [`codex-statusline`](recipes/codex-statusline) | `toml-merge` | Seed the **Codex CLI TUI status line** — the footer showing model, appro |
| [`colima`](recipes/colima) | `script` | Start [Colima](https://github.com/abiosoft/colima) as your local Docker  |
| [`commit-signing-1password`](recipes/commit-signing-1password) | `script` | Sign your git commits and tags with an SSH key that lives in **1Password |
| [`commit-signing-ssh`](recipes/commit-signing-ssh) | `script` | Sign your git commits and tags with an **SSH key** — the modern, no-GPG  |
| [`computer-name`](recipes/computer-name) | `script` | Set the Mac's name consistently — macOS stores it in **three** places th |
| [`dark-mode-auto`](recipes/dark-mode-auto) | `script` | Set the macOS system appearance to **Auto** (light by day, dark by night |
| [`debloat-apple-apps`](recipes/debloat-apple-apps) | `absent` | Remove Apple's bundled iLife apps (GarageBand, iMovie) that most dev mac |
| [`default-archive`](recipes/default-archive) | `script` | Set the default app that opens `.zip` archives — route them to Keka, The |
| [`default-browser`](recipes/default-browser) | `script` | Set your default web browser. |
| [`default-editor`](recipes/default-editor) | `script` | Open text and source-code files in your editor (VS Code, Sublime, Zed, … |
| [`default-image-viewer`](recipes/default-image-viewer) | `script` | Set the default app that opens images (Preview, XnView, Acorn, …) instea |
| [`default-mail`](recipes/default-mail) | `script` | Set your default **mailto:** client — the app that opens when you click  |
| [`default-pdf`](recipes/default-pdf) | `script` | Set the default app that opens PDFs (Preview, Skim, a browser, …). |
| [`default-terminal`](recipes/default-terminal) | `script` | Make your terminal the default app for shell scripts (so double-clicking |
| [`direnv-hook`](recipes/direnv-hook) | `block-in-file` | Hook [direnv](https://direnv.net) into zsh so per-directory `.envrc` fil |
| [`disable-autocorrect`](recipes/disable-autocorrect) | `defaults` | Turn off macOS's "smart" text substitutions — the ones that mangle code  |
| [`disable-startup-chime`](recipes/disable-startup-chime) | `script` | Silence the macOS **startup chime** — the sound the Mac plays at power-o |
| [`dock-items`](recipes/dock-items) | `script` | Curate the macOS Dock — pin the apps you want, remove the ones you don't |
| [`dock-minimal`](recipes/dock-minimal) | `defaults` | A minimal, stay-out-of-the-way Dock: **auto-hide** with **no reveal dela |
| [`expanded-save-panels`](recipes/expanded-save-panels) | `defaults` | Make macOS **Save** and **Print** dialogs open in their **expanded** for |
| [`fast-keyboard`](recipes/fast-keyboard) | `defaults` | Make the keyboard repeat as fast as macOS allows, and turn a held key in |
| [`finder-power-user`](recipes/finder-power-user) | `defaults` | A sensible Finder preference set for people who live in the filesystem. |
| [`fnm`](recipes/fnm) | `block-in-file` | Activate [fnm](https://github.com/Schniz/fnm) (Fast Node Manager) — a fa |
| [`fzf-setup`](recipes/fzf-setup) | `script` | Enable [fzf](https://github.com/junegunn/fzf)'s zsh integration — the ** |
| [`git-delta`](recipes/git-delta) | `script` | Render git diffs through [**delta**](https://github.com/dandavison/delta |
| [`git-lfs`](recipes/git-lfs) | `script` | Enable [Git LFS](https://git-lfs.com) for your user by installing its gl |
| [`git-maintenance`](recipes/git-maintenance) | `script` | Enable git's **background maintenance** for a repo — `git maintenance st |
| [`git-sensible-defaults`](recipes/git-sensible-defaults) | `script` | A set of opinionated global `git config` defaults most people set eventu |
| [`gitignore-global`](recipes/gitignore-global) | `script` | Install a curated **global gitignore** (OS cruft, editor/IDE dirs, local |
| [`krew`](recipes/krew) | `script` | Install [krew](https://krew.sigs.k8s.io), the plugin manager for `kubect |
| [`kubectl-context`](recipes/kubectl-context) | `script` | Set your default `kubectl` context to a named context that already lives |
| [`lockscreen-immediate`](recipes/lockscreen-immediate) | `script` | Require your password **immediately** when the screen locks or the scree |
| [`menu-clock`](recipes/menu-clock) | `defaults` | Force a **24-hour** clock in the menu bar (and everywhere macOS formats  |
| [`mise`](recipes/mise) | `block-in-file` | Activate [mise](https://mise.jdx.dev) — the polyglot runtime version man |
| [`modern-cli-aliases`](recipes/modern-cli-aliases) | `block-in-file` | Swap the classic CLI tools for their modern replacements in interactive  |
| [`oh-my-zsh`](recipes/oh-my-zsh) | `script` | Install [Oh My Zsh](https://ohmyz.sh) unattended into `~/.oh-my-zsh`, wi |
| [`pipx`](recipes/pipx) | `script` | Put [pipx](https://pipx.pypa.io)'s app directory (`~/.local/bin`) on you |
| [`pyenv`](recipes/pyenv) | `script` | Set up [pyenv](https://github.com/pyenv/pyenv) — the Python version mana |
| [`rbenv`](recipes/rbenv) | `block-in-file` | Initialize [rbenv](https://github.com/rbenv/rbenv) — the Ruby version ma |
| [`reduce-transparency`](recipes/reduce-transparency) | `defaults` | Turn on **Reduce transparency** — make the menu bar, Dock, sidebars, Not |
| [`rosetta`](recipes/rosetta) | `script` | Install **Rosetta 2** on Apple Silicon so x86_64-only apps and tools run |
| [`screenshots`](recipes/screenshots) | `script` | Save screenshots to **`~/Screenshots`** instead of littering the Desktop |
| [`shared-skills-dirs`](recipes/shared-skills-dirs) | `script` | One shared home for agent **skills** — drop a skill once, every coding a |
| [`sleep-settings`](recipes/sleep-settings) | `script` | Set display/disk sleep timers and disable **Power Nap**, via `pmset`. |
| [`ssh-config-github`](recipes/ssh-config-github) | `script` | Add a ready-to-use **`github.com` Host block** to `~/.ssh/config` and ** |
| [`ssh-key`](recipes/ssh-key) | `script` | Generate a personal **ed25519** SSH key if you don't have one, then load |
| [`starship-preset`](recipes/starship-preset) | `script` | Seed `~/.config/starship.toml` with one of [Starship](https://starship.r |
| [`tfenv`](recipes/tfenv) | `script` | Install [tfenv](https://github.com/tfutils/tfenv), a Terraform version m |
| [`tmux-tpm`](recipes/tmux-tpm) | `script` | Install the [Tmux Plugin Manager (TPM)](https://github.com/tmux-plugins/ |
| [`touchid-sudo`](recipes/touchid-sudo) | `script` | Authenticate `sudo` with **Touch ID** (and a paired Apple Watch, if you  |
| [`uv`](recipes/uv) | `command-if-missing` | Install [uv](https://docs.astral.sh/uv/) — Astral's fast, Rust-built Pyt |
| [`zoxide`](recipes/zoxide) | `block-in-file` | Initialize [zoxide](https://github.com/ajeetdsouza/zoxide) — a smarter ` |

_This is a machine-drafted batch, adversarially reviewed and gated (`shellcheck` +
`kitout validate` on every recipe). Privileged/destructive ones warrant a read before
you rely on them._

## Contributing

See [RECIPE-FORMAT.md](RECIPE-FORMAT.md). A recipe needs docs, a `test.bats`, and a
`## Security` section, and must pass `shellcheck` + its test in CI. PRs welcome —
recipes that run on other people's machines get reviewed accordingly.
