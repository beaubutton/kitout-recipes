# bun

Install [bun](https://bun.sh) — the fast, all-in-one JavaScript/TypeScript runtime,
package manager, bundler, and test runner — if it isn't already on `PATH`.

## What it does

Uses kitout's `command-if-missing` step: it probes for `bun` on `PATH` and, **only
when it's absent**, runs the installer — here `brew install oven-sh/bun/bun` (the
official `oven-sh/bun` tap). The probe is the convergence check, so `plan`/`status`
are honest (present → satisfied, missing → pending) and a second `apply` is a no-op.
No script.

Bun is a single binary that also provides `bunx` (its npx-style runner). Installing
it gives you a Node-compatible runtime plus a drop-in `npm`/`yarn`/`pnpm`-style
package manager.

## Requirements

- Homebrew on `PATH`. The default installer uses the `oven-sh/bun` tap; `brew` adds
  the tap automatically when it sees the fully-qualified `oven-sh/bun/bun` name.
- **Apple Silicon or x86-64 macOS.** Bun ships prebuilt binaries for both; on Intel
  it requires a CPU with AVX2.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. If you want a non-Homebrew
source, edit the `install` argv. Nothing to copy into `steps/`. After applying,
`bun --version`.

## Caveats

- The `probe` is **presence only** — if `bun` is already installed (by any means),
  the step is satisfied and won't upgrade it. Upgrade with `brew upgrade bun` (or
  `bun upgrade` for a non-brew install).
- `install` runs **without a shell**, so it's an argv list, not a pipeline. To use
  bun's official `curl … | bash` installer you'd wrap it (`["sh","-c","curl … | bash"]`)
  — and then re-read Security.
- Bun is Node-*compatible*, not Node-*identical*; some native-addon or edge npm
  packages still behave differently. It doesn't install or replace `node`.

## Security

Moderate, and it depends on which installer you keep.

- **As shipped (`brew install oven-sh/bun/bun`):** no privilege, no `curl | bash`.
  Adding the `oven-sh/bun` tap points Homebrew at Oven's formula repo; trust reduces
  to that tap plus Homebrew — the same boundary as any tapped `brew install`. No sudo.
- **The tool it installs:** bun is a general-purpose runtime and package manager — it
  runs arbitrary JS/TS and, like `npm`, executes package lifecycle scripts on
  `bun install` unless you pass `--ignore-scripts`. That is the normal exposure of a
  JS package manager, not something this step adds; nothing runs at *install* time
  here beyond fetching bun itself.
- **If you swap in bun's remote-script installer** (`curl … | bash`): you execute
  whatever that URL serves at apply time. Pin a version or verify the checksum, or
  prefer the Homebrew form. This recipe defaults to Homebrew to avoid blind
  `curl | bash`.
- **Reverse it:** `brew uninstall bun` (and `brew untap oven-sh/bun` if you want the
  tap gone), or remove `~/.bun` for a non-brew install.
