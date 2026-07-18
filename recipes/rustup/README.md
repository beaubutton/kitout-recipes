# rustup

Install [rustup](https://rustup.rs) — the official Rust toolchain
installer/manager — if it isn't already on `PATH`.

## What it does

Uses kitout's `command-if-missing` step: it probes for `rustup` on `PATH` and,
**only when it's absent**, runs the installer — here `brew install rustup` (the
Homebrew formula installs the `rustup` binary directly; as of formula 1.29.0 it
no longer provides a separate `rustup-init`). The probe is the convergence
check, so `plan`/`status` are honest (present → satisfied, missing → pending)
and a second `apply` is a no-op. No script.

**Why Homebrew and not the official installer:** rustup's documented install
method is `curl https://sh.rustup.rs -sSf | sh` — piping a remote script
straight to a shell. `command-if-missing`'s `install` runs as a plain argv (no
shell), so using the official one-liner as-is isn't even possible without
wrapping it in `sh -c`; this recipe uses Homebrew's package instead, which
avoids that pattern entirely and gives you an update path (`brew upgrade
rustup`) for free.

Installing the package alone does **not** set up a default toolchain — see
Adopt.

## Requirements

- Homebrew on `PATH` (the installer is `brew install rustup`).

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest.
2. `kitout apply`.
3. **Run once, by hand, after install:** `rustup default stable` (installs and
   activates the stable toolchain). Homebrew's `rustup` package installs the
   manager only — no toolchain is active until you do this. (The formula no
   longer ships `rustup-init`; `rustup default <channel>` is the entrypoint.)
4. Pairs with the [`cargo-env`](../cargo-env) recipe, which wires
   `~/.cargo/env` into your shell so `cargo`/`rustc` resolve in new shells.

Nothing to copy into `steps/`.

## Caveats

- The `probe` is **presence only** — if `rustup` is already installed (by any
  means, including the official installer), the step is satisfied and won't
  reinstall or upgrade it. Upgrades are `brew upgrade rustup` (or `rustup
  self update` for a non-brew install), not this step.
- `install` runs **without a shell**, so it's an argv list, not a pipeline —
  the official `curl … | sh` installer can't be dropped in verbatim (see
  Security if you do wrap it that way).
- This step only gets `rustup` onto the machine; it does not install a
  toolchain (`stable`, `nightly`, …) or put `cargo`/`rustc` on `PATH` for new
  shells — that's `rustup default <channel>` plus the `cargo-env` recipe.

## Security

Moderate, and it depends on which installer you keep.

- **As shipped (`brew install rustup`):** no privilege, no `curl | sh`. Trust
  reduces to Homebrew and the `rustup` formula — the same trust boundary as any
  `brew install`. No sudo.
- **The tool it installs:** rustup is a toolchain *manager* — once you run
  `rustup default stable` (or install any toolchain), it downloads and installs
  Rust's compiler and standard library from Rust's release channels. From
  there, `cargo build`/`cargo install` run project `build.rs` scripts and
  proc-macros as part of a normal build — the same exposure as any compiler
  toolchain or package manager; nothing runs at *install* time here beyond
  fetching rustup itself.
- **If you swap in the official remote-script installer** (`curl … | sh`): you
  are executing whatever that URL serves at apply time. Pin a version and/or
  verify the checksum, or prefer the Homebrew form. This recipe defaults to
  Homebrew precisely to avoid blind `curl | sh`.
- **Reverse it:** `rustup self uninstall` (removes toolchains and `~/.cargo`,
  `~/.rustup`), then `brew uninstall rustup`.
