# krew

Install [krew](https://krew.sigs.k8s.io), the plugin manager for `kubectl`, into
`~/.krew`.

## What it does

Bootstraps krew the way its docs prescribe, but without the usual `curl | bash`:
the script downloads the release tarball for your OS/arch from the
`kubernetes-sigs/krew` GitHub **release to disk**, unpacks it, and runs
`krew install krew` so krew registers itself as a kubectl plugin. Everything lands
under `~/.krew` (override with `KREW_ROOT`).

After installing, krew plugins are invoked as `kubectl krew …` and
`kubectl <plugin>` once `~/.krew/bin` is on your `PATH`.

The step's `check` tests for `~/.krew/bin/kubectl-krew`, so `plan`/`status` are
honest and the script exits immediately once krew is present.

## Requirements

- `kubectl` on PATH (macOS: `brew "kubectl"`). Point the step's `needs` at
  whatever installs it.
- `curl`, `tar` (stock macOS), and enough network to reach GitHub releases.
- **PATH:** add `~/.krew/bin` to your shell `PATH` to actually run plugins — e.g.
  a `block-in-file` line in `~/.zshrc`:
  `export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"`.

## Adopt

1. Copy `krew.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. `kitout apply`, then add `~/.krew/bin` to your PATH and open a new shell.
4. Verify: `kubectl krew version`.

## Caveats

- **PATH is on you.** kitout installs krew but doesn't edit your shell rc; until
  `~/.krew/bin` is on PATH, `kubectl krew` won't resolve. See `modern-cli-aliases`
  for the `block-in-file` pattern if you want kitout to manage that line too.
- Installs the **latest** krew at apply time. It does not pin a version and does
  not auto-update; run `kubectl krew upgrade` yourself.
- Installing krew installs the manager only — **no plugins**. Add those with
  `kubectl krew install <plugin>` (that step reaches the network and is out of
  scope here).

## Security

**Downloads and runs a release binary from GitHub — no sudo, user-scoped.**

- **Network + third-party code:** the script fetches `krew-<os>_<arch>.tar.gz`
  from the official `kubernetes-sigs/krew` GitHub release over HTTPS and executes
  it to self-install. You are trusting the krew project and GitHub's release
  integrity — the same trust as the upstream one-liner, but this variant downloads
  to disk first (**no `curl | bash`**), so you can inspect the tarball before it
  runs if you wish.
- **No sudo, no system files.** Everything installs under `~/.krew`, owned by you.
  This recipe never uses `sudo` and touches nothing outside your home directory.
- **Latest, unpinned:** it always grabs the newest krew. If you need a pinned,
  audited version, download a specific release tag and adjust the script's `url`.
- **Plugins are a separate trust decision:** krew itself is just the manager. Each
  `kubectl krew install <plugin>` you run later pulls community code from the krew
  index — vet plugins individually.
- **Reverse it:** `rm -rf ~/.krew` and remove the PATH entry.
