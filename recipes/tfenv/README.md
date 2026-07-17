# tfenv

Install [tfenv](https://github.com/tfutils/tfenv), a Terraform version manager,
into `~/.tfenv`.

## What it does

Clones the `tfutils/tfenv` repo into `~/.tfenv` (override with `TFENV_ROOT`) —
tfenv is pure shell, so the git checkout *is* the install. Once `~/.tfenv/bin` is
on your `PATH`, `tfenv install <version>` downloads that Terraform build on demand
and `tfenv use <version>` / a repo's `.terraform-version` file selects it, so
different projects can pin different Terraform versions.

The step's `check` tests for `~/.tfenv/bin/tfenv`, so `plan`/`status` are honest
and the script exits fast once tfenv is present.

## Requirements

- `git` on PATH (stock on macOS via the Command Line Tools; or `brew "git"`).
- **PATH:** add `~/.tfenv/bin` to your shell `PATH` — e.g. a `block-in-file` line
  in `~/.zshrc`: `export PATH="${TFENV_ROOT:-$HOME/.tfenv}/bin:$PATH"`.
- Network access to GitHub (clone) and, later, to HashiCorp's release host when
  you `tfenv install` a Terraform version.

## Adopt

1. Copy `tfenv.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. `kitout apply`, then add `~/.tfenv/bin` to your PATH and open a new shell.
4. Verify: `tfenv --version`, then `tfenv install latest && tfenv use latest`.

## Caveats

- **Homebrew alternative:** `brew "tfenv"` also works and self-manages updates. If
  you prefer that, use a `brew` step instead of this recipe — the two conflict if
  both put a `tfenv`/`terraform` shim on PATH, so pick one.
- **PATH is on you.** This installs tfenv but doesn't edit your shell rc; until
  `~/.tfenv/bin` precedes any other `terraform` on PATH, `terraform` won't resolve
  to tfenv's shim.
- **No Terraform yet.** Installing tfenv installs the *manager*; you still run
  `tfenv install <version>` to get a Terraform binary (that step hits the network).
- **Updates:** a git-clone install updates via `git -C ~/.tfenv pull`, not
  Homebrew.
- Terraform's license (BSL) is unrelated to tfenv; if you're on OpenTofu, use
  `tofuenv` instead.

## Security

**Clones a git repo into your home dir — no sudo, user-scoped.**

- **Network + third-party code:** the script `git clone`s `tfutils/tfenv` from
  GitHub over HTTPS. You're trusting that repo (and GitHub) — the same trust as the
  upstream install instructions. It's a shallow clone of shell scripts you can read
  under `~/.tfenv` before adding it to PATH.
- **No sudo, no system files.** Everything lands under `~/.tfenv`, owned by you.
  This recipe never uses `sudo` and touches nothing outside your home directory.
- **Deferred trust:** tfenv later downloads Terraform binaries from HashiCorp's
  releases when you `tfenv install`. tfenv verifies those against HashiCorp's
  published checksums/signatures; that fetch is your call, not this step's.
- **Unpinned tip:** it clones the default branch (latest tfenv). To pin, add
  `--branch <tag>` to the `git clone` in the script.
- **Reverse it:** `rm -rf ~/.tfenv` and remove the PATH entry.
