# deno

Install [Deno](https://deno.com) — a JavaScript/TypeScript/WebAssembly runtime
that's sandboxed by default — if it isn't already on `PATH`.

## What it does

Uses kitout's `command-if-missing` step: it probes for `deno` on `PATH` and,
**only when it's absent**, runs the installer — here `brew install deno`. The
probe is the convergence check, so `plan`/`status` are honest (present →
satisfied, missing → pending) and a second `apply` is a no-op. No script.

Deno ships TypeScript support, a formatter, linter, and test runner built in —
no separate toolchain needed to run a `.ts` file directly.

## Requirements

- Homebrew on `PATH` (the default installer is `brew install deno`). To avoid
  Homebrew, replace `install` with Deno's official install script or a
  released binary — see Security before piping a remote script.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. If you want a
non-Homebrew source, edit the `install` argv. Nothing to copy into `steps/`.
After applying, `deno --version`.

## Caveats

- The `probe` is **presence only** — if `deno` is already installed (by any
  means), the step is satisfied and won't upgrade it. Upgrades are `brew
  upgrade deno` (or `deno upgrade` for a non-brew install), not this step.
- `install` runs **without a shell**, so it's an argv list, not a pipeline. To
  use Deno's official `curl … | sh` installer you must wrap it (`["sh", "-c",
  "curl … | sh"]`) — and then re-read Security.

## Security

Low, with one thing worth understanding about the runtime itself.

- **As shipped (`brew install deno`):** no privilege, no `curl | sh`. Trust
  reduces to Homebrew and the `deno` formula — the same trust boundary as any
  `brew install`. No sudo.
- **The runtime is sandboxed by default — this is Deno's headline security
  property.** Unlike Node, a script run with plain `deno run script.ts` has
  **no** file, network, environment, or subprocess access until you grant it
  explicitly with flags: `--allow-read`, `--allow-write`, `--allow-net`,
  `--allow-env`, `--allow-run`, or the blanket `--allow-all` / `-A`. Reading
  someone else's `deno run -A ...` instructions is equivalent to reading "run
  this with no sandbox" — treat a bare `-A` the same as you'd treat running any
  untrusted script unsandboxed.
- **Nothing runs at install time here** beyond fetching the `deno` binary
  itself; the sandboxing applies to scripts *you* choose to run afterward.
- **Reverse it:** `brew uninstall deno` (or remove the binary the alternate
  installer placed, typically `~/.deno`).
