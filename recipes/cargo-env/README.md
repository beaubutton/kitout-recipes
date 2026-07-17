# cargo-env

Source Rust's own `~/.cargo/env` file — the shell wiring that puts
`cargo`/`rustc` on `PATH` — in zsh.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:cargo-env >>>` … `# <<< recipes:cargo-env <<<`) containing:

```zsh
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
```

`~/.cargo/env` is a file that rustup/cargo itself generates on install; it
exports `CARGO_HOME`/`RUSTUP_HOME` and puts `~/.cargo/bin` on `PATH`. The
`[ -f … ]` guard means this block is safe to apply **before** Rust is
installed: it does nothing until `~/.cargo/env` actually exists, so an
unconverted machine just gets a harmless no-op in every new shell instead of a
sourcing error. Everything outside the markers stays yours; kitout only
rewrites the block. No script.

**Pairs with the [`rustup`](../rustup) recipe** — that one installs the
`rustup` manager; this one wires the shell so `cargo`/`rustc` resolve once a
toolchain exists.

## Requirements

- Rust installed via rustup (`~/.cargo/env` is written by rustup's own
  installer, whether that's `rustup-init` from the `rustup` recipe or the
  official `curl | sh` script). No requirement if you haven't installed Rust
  yet — see What it does.
- A zsh login shell. For bash, target `~/.bashrc` instead (`~/.cargo/env` is
  POSIX `sh`-compatible, so the same line works).

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest.
2. `kitout apply`.
3. If you haven't already, install Rust via the [`rustup`](../rustup) recipe
   (or rustup's own installer) and run `rustup default stable`.
4. Open a new shell, then `cargo --version` and `rustc --version`.

Nothing to copy into `steps/`.

## Caveats

- **Doesn't install Rust.** If `~/.cargo/env` never gets created, the block
  silently no-ops forever — adopt the `rustup` recipe (or run rustup's
  installer) to actually get a toolchain.
- Applies to **new** shells — `source ~/.zshrc` or open a new terminal for the
  session that ran `apply`.
- If you use a version manager for Rust toolchains other than rustup, this
  recipe assumes the standard `~/.cargo` layout; adjust the path if yours
  differs.

## Security

None beyond a normal shell-config edit. It manages a marked block in your own
`~/.zshrc` — no privilege, no network, and it never touches the rest of the
file. `~/.cargo/env` (when present) only exports environment variables and
extends `PATH`; it runs no other commands. Once `cargo`/`rustc` are on `PATH`,
using them (`cargo build`, `cargo install`) runs project `build.rs` scripts and
proc-macros as part of a normal build — the same exposure as any compiler
toolchain, not something this recipe adds. Reverse by removing the block from
`~/.zshrc`.
