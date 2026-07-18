# npm-global-prefix

Point npm's **global install prefix** at a directory you own, so
`npm install -g` never needs `sudo`.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:npm-global-prefix >>>` … `# <<< recipes:npm-global-prefix <<<`)
containing:

```zsh
export NPM_CONFIG_PREFIX="$HOME/.npm-global"
export PATH="$HOME/.npm-global/bin:$PATH"
```

`NPM_CONFIG_PREFIX` is npm's environment-variable form of `npm config set
prefix` — it tells npm where to place globally installed packages and their
bin shims. Pointing it at `~/.npm-global` (a directory under your own home,
created on first `npm install -g` if it doesn't exist) means npm never needs
to write into a root-owned location like `/usr/local/lib/node_modules`, so
`sudo npm install -g …` becomes unnecessary. The `PATH` line makes the
resulting shims (`~/.npm-global/bin`) runnable. Everything outside the markers
stays yours; kitout only rewrites the block. No script.

## Requirements

- The `npm` binary on `PATH` (ships with any Node install — Homebrew's `node`,
  or a version manager like fnm/nvm/volta/asdf). Point the step's `needs` at
  whatever installs Node.
- A zsh login shell. For bash, target `~/.bashrc` instead (same lines work).

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest; add
   `needs = ["<your node/npm step>"]`.
2. `kitout apply`, then open a new shell (or `source ~/.zshrc`).
3. **Re-install any existing global packages** — see Caveats: packages
   installed under the old prefix aren't automatically moved.
4. `npm install -g <package>` and confirm no `sudo` is needed and the binary
   resolves.

Nothing to copy into `steps/`.

## Caveats

- **Changes where global installs live — it doesn't move what's already
  there.** Any package you installed globally *before* adopting this recipe
  (typically under `/usr/local/lib/node_modules` or a version manager's own
  global dir) stays where it was; only *new* global installs land in
  `~/.npm-global`. Re-run `npm install -g <pkg>` for anything you rely on
  (`npm list -g --depth=0`, from **before** switching, tells you what to
  reinstall).
- **Version managers may already solve this for you.** fnm, nvm, volta, and
  asdf each keep global installs under a per-version, user-owned directory
  already — if you use one of those, you likely don't need this recipe at all;
  it's aimed at a plain Homebrew/system Node setup where the default prefix is
  root-owned.
- Applies to **new** shells — `source ~/.zshrc` or open a new terminal for the
  session that ran `apply`.

## Security

None from this step itself — it's a `PATH`/config export in your own
`~/.zshrc`, no privilege, no network. The practical effect is the **opposite**
of a risk: it removes the habit of running `sudo npm install -g`, which is
worth avoiding because it runs an npm package's install scripts **as root**
against a system directory. After adopting, `npm install -g` installs and runs
that package's lifecycle scripts as your own user against `~/.npm-global` —
still the normal exposure of any package manager (arbitrary scripts from
whatever you install), just correctly scoped to your account instead of root.
Reverse by removing the block from `~/.zshrc` (global packages already under
`~/.npm-global` stay there until you remove them by hand:
`rm -rf ~/.npm-global`).
