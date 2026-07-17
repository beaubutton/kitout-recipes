# pyenv

Set up [pyenv](https://github.com/pyenv/pyenv) — the Python version manager — with
its shell hook and a default CPython, so `python` resolves to a pyenv-managed 3.x
instead of the system Python.

## What it does

A `script` step that:

1. **Installs the shell hook** into `~/.zshrc` as a self-contained managed block
   (`# >>> recipes:pyenv >>>` … `# <<< recipes:pyenv <<<`) — it sets `PYENV_ROOT`,
   puts `$PYENV_ROOT/bin` on `PATH`, and runs `eval "$(pyenv init - zsh)"`. The
   block is appended once and never duplicated; the rest of your `~/.zshrc` is
   untouched.
2. **Installs the latest stable CPython 3.x** via `pyenv install --skip-existing
   "$(pyenv latest -k 3)"` and makes it the **global** default (`pyenv global`).

The step's `check` is satisfied once `pyenv global` reports a `3.x` version, so
`plan`/`status` are honest and the script no-ops once converged.

This recipe assumes the **`pyenv` binary is already installed** (see Requirements);
it wires up the shell and installs a Python, it does not install pyenv itself.

## Requirements

- The `pyenv` binary on `PATH`: `brew "pyenv"`. Point the step's `needs` at it.
- **pyenv ≥ 2.3.0** for `pyenv latest` (Homebrew's pyenv is far newer). Without it,
  the script exits with a message telling you to `pyenv install <version>` by hand.
- **A working build toolchain** — pyenv *compiles* CPython from source. On macOS
  that means Xcode Command Line Tools plus pyenv's suggested build deps
  (`brew "openssl"`, `"readline"`, `"xz"`, …). See pyenv's
  [wiki: Common build problems](https://github.com/pyenv/pyenv/wiki/Common-build-problems).
- No privilege — everything lands under `~/.pyenv` and `~/.zshrc`.

## Adopt

1. Copy `pyenv.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml`; add `needs = ["<your pyenv install step>"]`.
3. `kitout apply`. First run **compiles CPython** — expect a few minutes.
4. Open a new shell (or `source ~/.zshrc`), then `python --version` and `pyenv which python`.

## Caveats

- **First apply is slow** — it builds CPython from source. Missing build deps show up
  as a compile failure, not a kitout bug; install pyenv's suggested deps and re-apply.
- **zsh only** as written (the hook uses `pyenv init - zsh`). For bash, change the
  block in `pyenv.sh` to `bash` and append to `~/.bashrc`.
- The `check` only asserts *some* global 3.x is set; it won't chase new Python
  releases. To move up, `pyenv install <newer> && pyenv global <newer>` yourself.
- If `pyenv` isn't on `PATH` when the script runs, it exits non-zero with a hint —
  put the install step in `needs`.
- **Default `PYENV_ROOT` (`~/.pyenv`) assumed.** The `~/.zshrc` block hardcodes
  `export PYENV_ROOT="$HOME/.pyenv"`. If you keep pyenv somewhere else, edit that
  line in `pyenv.sh` (and set `PYENV_ROOT` before applying) so the install location
  and the shell hook agree.

## Security

Low–moderate; no privilege, but it does fetch and compile code.

- **No sudo, no system files.** It writes only `~/.zshrc` (its own marked block) and
  `~/.pyenv`. Reverse by deleting the block and `rm -rf ~/.pyenv`.
- **It downloads and compiles CPython** from python.org's release tarballs (via
  pyenv/`python-build`), then runs that interpreter as your default `python`. Trust
  reduces to pyenv's mirror list and the upstream CPython releases — the normal
  exposure of any source build. Nothing is installed with elevated privilege.
- **The shell hook** runs `eval "$(pyenv init - zsh)"` on every new shell, executing
  whatever the on-PATH `pyenv` emits — so the trust boundary is the pyenv binary you
  installed via Homebrew.
- **`.python-version` files** in a repo make pyenv *select* a version you've
  installed (it selects, it does not auto-install or run project code) — the same
  trust you extend to any repo you work in.
