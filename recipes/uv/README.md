# uv

Install [uv](https://docs.astral.sh/uv/) — Astral's fast, Rust-built Python package,
project, and Python-version manager (a drop-in for `pip`, `pip-tools`, `pipx`,
`venv`, and `pyenv`) — if it isn't already on `PATH`.

## What it does

Uses kitout's `command-if-missing` step: it probes for `uv` on `PATH` and, **only
when it's absent**, runs the installer — here `brew install uv`. The probe is the
convergence check, so `plan`/`status` are honest (present → satisfied, missing →
pending) and a second `apply` is a no-op. No script.

Installing uv also gives you `uvx` (its `pipx`-style tool runner). uv can manage its
own Python interpreters (`uv python install`), so it can stand in for pyenv too.

## Requirements

- Homebrew on `PATH` (the default installer is `brew install uv`). To avoid
  Homebrew, replace `install` with Astral's official script or a `pip`/`pipx`
  install — see Security before piping a remote script.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. If you want a non-Homebrew
source, edit the `install` argv. Nothing to copy into `steps/`. After applying,
`uv --version`.

## Caveats

- The `probe` is **presence only** — if `uv` is already installed (by any means),
  the step is satisfied and won't upgrade it. Upgrades are `brew upgrade uv` (or
  `uv self update` for a non-brew install), not this step.
- `install` runs **without a shell**, so it's an argv list, not a pipeline. To use
  Astral's `curl … | sh` installer you must wrap it (`["sh","-c","curl … | sh"]`) —
  and then re-read Security.

## Security

Moderate, and it depends on which installer you keep.

- **As shipped (`brew install uv`):** no privilege, no `curl | sh`. Trust reduces to
  Homebrew and Astral's formula — the same trust boundary as any `brew install`. No
  sudo.
- **The tool it installs:** uv resolves and installs Python packages and, on request,
  downloads prebuilt Python interpreters from Astral's `python-build-standalone`
  distribution — it reaches the network and executes package build/install code, the
  normal exposure of any package manager. Nothing runs at *install* time here beyond
  fetching uv itself.
- **If you swap in a remote-script installer** (`curl … | sh`): you are executing
  whatever that URL serves at apply time. Pin a version and/or verify the checksum,
  or prefer the Homebrew form. This recipe defaults to Homebrew precisely to avoid
  blind `curl | sh`.
- **Reverse it:** `brew uninstall uv` (or remove the binary the alternate installer
  placed, typically `~/.local/bin/uv`).
