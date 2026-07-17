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
| [`accent-color`](recipes/accent-color) | `defaults` | Set the macOS **accent color** (buttons, selected controls, checkboxes) |
| [`agents-md-global`](recipes/agents-md-global) | `block-in-file` | Seed a **global `AGENTS.md`** — the house rules every coding agent reads |
| [`app-firewall`](recipes/app-firewall) | `script` | Enable macOS's built-in **application firewall** and **stealth mode**. |
| [`asdf`](recipes/asdf) | `block-in-file` | Activate [asdf](https://asdf-vm.com) — the multi-language version manage |
| [`atuin`](recipes/atuin) | `block-in-file` | Initialize [Atuin](https://atuin.sh) — a SQLite-backed replacement for y |
| [`auto-security-updates`](recipes/auto-security-updates) | `script` | Enable automatic installation of Apple's **security** updates — without |
| [`aws-profile`](recipes/aws-profile) | `block-in-file` | Scaffold a named AWS profile in `~/.aws/config` — region, output format, |
| [`bat-config`](recipes/bat-config) | `block-in-file` | Configure [bat](https://github.com/sharkdp/bat)'s color theme and make i |
| [`bun`](recipes/bun) | `command-if-missing` | Install [bun](https://bun.sh) — the fast, all-in-one JavaScript/TypeScri |
| [`caps-to-control`](recipes/caps-to-control) | `script` | Remap **Caps Lock → Control**, and make it stick across reboots. |
| [`cargo-env`](recipes/cargo-env) | `block-in-file` | Source Rust's own `~/.cargo/env` file — the shell wiring that puts `carg |
| [`claude-statusline`](recipes/claude-statusline) | `json-merge` | Seed a **Claude Code status line** — model, context-window usage, and cu |
| [`codex-statusline`](recipes/codex-statusline) | `toml-merge` | Seed the **Codex CLI TUI status line** — the footer showing model, appro |
| [`colima`](recipes/colima) | `script` | Start [Colima](https://github.com/abiosoft/colima) as your local Docker |
| [`commit-signing-1password`](recipes/commit-signing-1password) | `script` | Sign your git commits and tags with an SSH key that lives in **1Password |
| [`commit-signing-gpg`](recipes/commit-signing-gpg) | `script` | Sign your git commits and tags with a **GPG key** — the classic path to |
| [`commit-signing-ssh`](recipes/commit-signing-ssh) | `script` | Sign your git commits and tags with an **SSH key** — the modern, no-GPG |
| [`computer-name`](recipes/computer-name) | `script` | Set the Mac's name consistently — macOS stores it in **three** places th |
| [`custom-dns`](recipes/custom-dns) | `script` | Set the **DNS resolvers** for a network service (Wi-Fi, Ethernet, …) to |
| [`dark-mode-auto`](recipes/dark-mode-auto) | `script` | Set the macOS system appearance to **Auto** (light by day, dark by night |
| [`debloat-apple-apps`](recipes/debloat-apple-apps) | `absent` | Remove Apple's bundled iLife apps (GarageBand, iMovie) that most dev mac |
| [`default-archive`](recipes/default-archive) | `script` | Set the default app that opens `.zip` archives — route them to Keka, The |
| [`default-browser`](recipes/default-browser) | `script` | Set your default web browser. |
| [`default-editor`](recipes/default-editor) | `script` | Open text and source-code files in your editor (VS Code, Sublime, Zed, … |
| [`default-image-viewer`](recipes/default-image-viewer) | `script` | Set the default app that opens images (Preview, XnView, Acorn, …) instea |
| [`default-mail`](recipes/default-mail) | `script` | Set your default **mailto:** client — the app that opens when you click |
| [`default-pdf`](recipes/default-pdf) | `script` | Set the default app that opens PDFs (Preview, Skim, a browser, …). |
| [`default-terminal`](recipes/default-terminal) | `script` | Make your terminal the default app for shell scripts (so double-clicking |
| [`deno`](recipes/deno) | `command-if-missing` | Install [Deno](https://deno.com) — a JavaScript/TypeScript/WebAssembly r |
| [`direnv-hook`](recipes/direnv-hook) | `block-in-file` | Hook [direnv](https://direnv.net) into zsh so per-directory `.envrc` fil |
| [`disable-autocorrect`](recipes/disable-autocorrect) | `defaults` | Turn off macOS's "smart" text substitutions — the ones that mangle code |
| [`disable-startup-chime`](recipes/disable-startup-chime) | `script` | Silence the macOS **startup chime** — the sound the Mac plays at power-o |
| [`dock-items`](recipes/dock-items) | `script` | Curate the macOS Dock — pin the apps you want, remove the ones you don't |
| [`dock-magnification`](recipes/dock-magnification) | `defaults` | Turn on Dock magnification: icons grow as the pointer passes over them, |
| [`dock-minimal`](recipes/dock-minimal) | `defaults` | A minimal, stay-out-of-the-way Dock: **auto-hide** with **no reveal dela |
| [`expanded-save-panels`](recipes/expanded-save-panels) | `defaults` | Make macOS **Save** and **Print** dialogs open in their **expanded** for |
| [`fast-keyboard`](recipes/fast-keyboard) | `defaults` | Make the keyboard repeat as fast as macOS allows, and turn a held key in |
| [`filevault-enable`](recipes/filevault-enable) | `script` | Enable **FileVault** — full-disk encryption of the startup volume. |
| [`finder-power-user`](recipes/finder-power-user) | `defaults` | A sensible Finder preference set for people who live in the filesystem. |
| [`fnm`](recipes/fnm) | `block-in-file` | Activate [fnm](https://github.com/Schniz/fnm) (Fast Node Manager) — a fa |
| [`fzf-setup`](recipes/fzf-setup) | `script` | Enable [fzf](https://github.com/junegunn/fzf)'s zsh integration — the ** |
| [`gatekeeper-on`](recipes/gatekeeper-on) | `script` | Ensure **Gatekeeper** is enabled — the safe direction only. This recipe |
| [`gh-cli-config`](recipes/gh-cli-config) | `script` | Set sane [GitHub CLI](https://cli.github.com) (`gh`) defaults, idempoten |
| [`git-commit-template`](recipes/git-commit-template) | `script` | Seed a **Conventional Commits** skeleton as your global git commit messa |
| [`git-conditional-identity`](recipes/git-conditional-identity) | `script` | Use your personal git identity everywhere, except under `~/work/`, where |
| [`git-delta`](recipes/git-delta) | `script` | Render git diffs through [**delta** |
| [`git-lfs`](recipes/git-lfs) | `script` | Enable [Git LFS](https://git-lfs.com) for your user by installing its gl |
| [`git-maintenance`](recipes/git-maintenance) | `script` | Enable git's **background maintenance** for a repo — `git maintenance st |
| [`git-sensible-defaults`](recipes/git-sensible-defaults) | `script` | A set of opinionated global `git config` defaults most people set eventu |
| [`gitignore-global`](recipes/gitignore-global) | `script` | Install a curated **global gitignore** (OS cruft, editor/IDE dirs, local |
| [`gpg-tty`](recipes/gpg-tty) | `block-in-file` | Point GPG's pinentry at your current terminal, so passphrase prompts sho |
| [`hosts-block`](recipes/hosts-block) | `script` | Manage a small, user-editable ad/tracker **blocklist** in `/etc/hosts` — |
| [`hot-corners`](recipes/hot-corners) | `defaults` | Assign screen-corner actions (Mission Control, Lock Screen, Desktop, etc |
| [`jenv`](recipes/jenv) | `block-in-file` | Activate [jenv](https://www.jenv.be) — a lightweight Java version manage |
| [`krew`](recipes/krew) | `script` | Install [krew](https://krew.sigs.k8s.io), the plugin manager for `kubect |
| [`kubectl-context`](recipes/kubectl-context) | `script` | Set your default `kubectl` context to a named context that already lives |
| [`less-config`](recipes/less-config) | `block-in-file` | Sensible default flags for `less` — raw colors survive, short output doe |
| [`lockscreen-immediate`](recipes/lockscreen-immediate) | `script` | Require your password **immediately** when the screen locks or the scree |
| [`menu-bar-autohide`](recipes/menu-bar-autohide) | `defaults` | Auto-hide the menu bar, reclaiming that strip of screen until you move t |
| [`menu-clock`](recipes/menu-clock) | `defaults` | Force a **24-hour** clock in the menu bar (and everywhere macOS formats |
| [`mise`](recipes/mise) | `block-in-file` | Activate [mise](https://mise.jdx.dev) — the polyglot runtime version man |
| [`mission-control-defaults`](recipes/mission-control-defaults) | `defaults` | Keep your Spaces in a stable, predictable order and group windows by app |
| [`modern-cli-aliases`](recipes/modern-cli-aliases) | `block-in-file` | Swap the classic CLI tools for their modern replacements in interactive |
| [`natural-scroll-off`](recipes/natural-scroll-off) | `defaults` | Turn off "natural" scrolling — scrolling down moves you down the page/co |
| [`npm-global-prefix`](recipes/npm-global-prefix) | `block-in-file` | Point npm's **global install prefix** at a directory you own, so `npm in |
| [`oh-my-zsh`](recipes/oh-my-zsh) | `script` | Install [Oh My Zsh](https://ohmyz.sh) unattended into `~/.oh-my-zsh`, wi |
| [`pipx`](recipes/pipx) | `script` | Put [pipx](https://pipx.pypa.io)'s app directory (`~/.local/bin`) on you |
| [`pnpm-home`](recipes/pnpm-home) | `block-in-file` | Put pnpm's global bin directory (`PNPM_HOME`) on `PATH`, so packages ins |
| [`pre-commit-global`](recipes/pre-commit-global) | `script` | Make every **future** `git init`/`git clone` install [pre-commit |
| [`press-and-hold-off`](recipes/press-and-hold-off) | `defaults` | Disable the hold-a-key **accent-character popover** — holding a key repe |
| [`proxy-env`](recipes/proxy-env) | `block-in-file` | Seed **proxy environment-variable placeholders** into `~/.zshrc` — comme |
| [`pyenv`](recipes/pyenv) | `script` | Set up [pyenv](https://github.com/pyenv/pyenv) — the Python version mana |
| [`rbenv`](recipes/rbenv) | `block-in-file` | Initialize [rbenv](https://github.com/rbenv/rbenv) — the Ruby version ma |
| [`rclone-remote`](recipes/rclone-remote) | `block-in-file` | Scaffold the shell environment [rclone](https://rclone.org) needs to unl |
| [`reduce-motion`](recipes/reduce-motion) | `defaults` | Turn on **Reduce Motion**: cuts the zoom/parallax/Spaces-switch animatio |
| [`reduce-transparency`](recipes/reduce-transparency) | `defaults` | Turn on **Reduce transparency** — make the menu bar, Dock, sidebars, Not |
| [`remote-login-off`](recipes/remote-login-off) | `script` | Ensure **Remote Login** (macOS's built-in SSH server, `sshd`) is **off** |
| [`restic-scaffold`](recipes/restic-scaffold) | `block-in-file` | Scaffold the shell environment [restic](https://restic.net) needs — repo |
| [`rosetta`](recipes/rosetta) | `script` | Install **Rosetta 2** on Apple Silicon so x86_64-only apps and tools run |
| [`rustup`](recipes/rustup) | `command-if-missing` | Install [rustup](https://rustup.rs) — the official Rust toolchain instal |
| [`screenshots`](recipes/screenshots) | `script` | Save screenshots to **`~/Screenshots`** instead of littering the Desktop |
| [`scroll-bars-always`](recipes/scroll-bars-always) | `defaults` | Always show scroll bars, instead of macOS hiding them until you scroll ( |
| [`sdkman`](recipes/sdkman) | `block-in-file` | Wire [SDKMAN!](https://sdkman.io) — the SDK manager for Java, Kotlin, Gr |
| [`shared-skills-dirs`](recipes/shared-skills-dirs) | `script` | One shared home for agent **skills** — drop a skill once, every coding a |
| [`sleep-settings`](recipes/sleep-settings) | `script` | Set display/disk sleep timers and disable **Power Nap**, via `pmset`. |
| [`ssh-config-github`](recipes/ssh-config-github) | `script` | Add a ready-to-use **`github.com` Host block** to `~/.ssh/config` and ** |
| [`ssh-keepalive`](recipes/ssh-keepalive) | `block-in-file` | Stop idle **SSH sessions from dropping** — a `Host *` block with keepali |
| [`ssh-key`](recipes/ssh-key) | `script` | Generate a personal **ed25519** SSH key if you don't have one, then load |
| [`stage-manager-off`](recipes/stage-manager-off) | `defaults` | Turn **Stage Manager** off — the same switch as the Control Center toggl |
| [`starship-preset`](recipes/starship-preset) | `script` | Seed `~/.config/starship.toml` with one of [Starship |
| [`tap-to-click`](recipes/tap-to-click) | `defaults` | Enable **tap-to-click** — tap the trackpad to click, no physical press n |
| [`tfenv`](recipes/tfenv) | `script` | Install [tfenv](https://github.com/tfutils/tfenv), a Terraform version m |
| [`three-finger-drag`](recipes/three-finger-drag) | `defaults` | Enable **three-finger drag** — sweep three fingers on the trackpad to dr |
| [`time-machine-exclusions`](recipes/time-machine-exclusions) | `script` | Exclude dev-cruft directories (caches, build output) from Time Machine s |
| [`tmux-tpm`](recipes/tmux-tpm) | `script` | Install the [Tmux Plugin Manager (TPM) |
| [`touchid-sudo`](recipes/touchid-sudo) | `script` | Authenticate `sudo` with **Touch ID** (and a paired Apple Watch, if you |
| [`uv`](recipes/uv) | `command-if-missing` | Install [uv](https://docs.astral.sh/uv/) — Astral's fast, Rust-built Pyt |
| [`volta`](recipes/volta) | `block-in-file` | Wire [Volta](https://volta.sh) — a JavaScript tool manager that **pins** |
| [`vscode-extensions`](recipes/vscode-extensions) | `script` | Install a **user-editable list of VS Code extensions**, idempotently. |
| [`vscode-settings`](recipes/vscode-settings) | `json-merge` | Seed a handful of sane defaults into **VS Code's user `settings.json`** |
| [`xcode-command-line-tools`](recipes/xcode-command-line-tools) | `script` | Ensure the **Xcode Command Line Tools** — `clang`, `make`, `git`, system |
| [`zoxide`](recipes/zoxide) | `block-in-file` | Initialize [zoxide](https://github.com/ajeetdsouza/zoxide) — a smarter ` |
| [`zsh-history-opts`](recipes/zsh-history-opts) | `block-in-file` | A big, shared, deduplicated zsh command history — every session sees eve |

_This is a machine-drafted catalog, adversarially reviewed and gated (`shellcheck` +
`kitout validate` on every recipe). Privileged/destructive ones warrant a read before
you rely on them._

## Contributing

See [RECIPE-FORMAT.md](RECIPE-FORMAT.md). A recipe needs docs, a `test.bats`, and a
`## Security` section, and must pass `shellcheck` + its test in CI. PRs welcome —
recipes that run on other people's machines get reviewed accordingly.
