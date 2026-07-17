# rbenv

Initialize [rbenv](https://github.com/rbenv/rbenv) — the Ruby version manager — in
your interactive shell so `ruby`/`gem` resolve to the rbenv-selected version.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:rbenv >>>` … `# <<< recipes:rbenv <<<`) containing:

```sh
eval "$(rbenv init - zsh)"
```

`rbenv init -` prepends rbenv's `shims` directory to `PATH` and installs a shell
hook so the active Ruby follows the nearest `.ruby-version` (or `rbenv global`).
Everything outside the markers stays yours; kitout only rewrites the block. No
script.

This recipe installs the *shell hook*, not the rbenv binary or any Ruby — see
Requirements.

## Requirements

- The `rbenv` binary on `PATH`: `brew "rbenv"` (Homebrew pulls in `ruby-build`, which
  provides `rbenv install`). Point the step's `needs` at whatever installs it.
- To get a Ruby after adopting: `rbenv install 3.3.5 && rbenv global 3.3.5` (chosen
  version and the `rbenv install` are deliberately out of this recipe). Building a
  Ruby needs the usual toolchain (Xcode Command Line Tools, `openssl`, etc.).

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Add
`needs = ["<your rbenv install step>"]`. Nothing to copy into `steps/`. Open a new
shell (or `source ~/.zshrc`), then `rbenv --version` and install a Ruby.

## Caveats

- **zsh only** as written (`rbenv init - zsh`). For bash use `rbenv init - bash` and
  target `~/.bashrc`; fish needs `rbenv init - fish`.
- Applies to **new** shells — `source ~/.zshrc` or open a new terminal for the
  session that ran `apply`.
- Ships **no Ruby** — with none installed, `ruby` still falls through to the system
  Ruby until you `rbenv install` + set a version.
- Don't also init another Ruby manager (asdf/chruby/mise) for Ruby in the same shell.

## Security

Low. It edits a marked block in your own `~/.zshrc` — no privilege, no network at
apply time, and it never touches the rest of the file.

The added line runs `eval "$(rbenv init - zsh)"` **every time you open a shell**,
executing whatever the on-PATH `rbenv` binary emits — so the trust boundary is the
rbenv binary (install it from a source you trust; that's the Requirements step's
concern). Once active, rbenv reads the nearest `.ruby-version` to *select* a Ruby
(it selects, it does not download or run project code); a repo can thus steer which
of your installed Rubies runs its `gem`/`bundle` commands — the same trust you
extend to any repo you build. Reverse by deleting the block (or removing the recipe
and re-applying).
