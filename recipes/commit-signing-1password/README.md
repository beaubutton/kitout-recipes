# commit-signing-1password

Sign your git commits and tags with an SSH key that lives in **1Password** — the
private key never touches disk; 1Password signs on demand behind its own
approval prompt.

## What it does

Points git's SSH signing at 1Password's helper (git **2.34+**, 1Password **8**):

| Key | Value | Why |
|---|---|---|
| `gpg.format` | `ssh` | sign with an SSH key |
| `user.signingkey` | your **public** key string | which key (a literal key, not a file) |
| `gpg.ssh.program` | `…/1Password.app/Contents/MacOS/op-ssh-sign` | 1Password does the signing |
| `commit.gpgsign` | `true` | sign every commit |
| `tag.gpgsign` | `true` | sign annotated tags too |

Unlike the plain [`commit-signing-ssh`](../commit-signing-ssh) recipe, there is
**no private key on disk**: at commit time git calls `op-ssh-sign`, which asks
1Password to sign with the key stored in your vault (Touch ID / prompt as you've
configured). `user.signingkey` is the **literal public key string** (e.g.
`ssh-ed25519 AAAA… you@example.com`), because there's no `.pub` file to point at.

The step's `check` is satisfied once `gpg.ssh.program` resolves to `op-ssh-sign`
and `commit.gpgsign=true`, and each write is compared first, so re-applying is a
no-op.

## Requirements

- **1Password 8** (the desktop app) with the SSH agent enabled: Settings →
  Developer → *Use the SSH agent*. Install via `brew "1password"` if needed and
  point the step's `needs` at that step.
- An **SSH key stored in 1Password** (create one in the app, or import an
  existing key).
- **git 2.34+** (ships on current macOS).
- **Edit `SIGNING_KEY`** in `commit-signing-1password.sh` to your public key —
  1Password shows it in the key item ("Configure" / the git-signing snippet).
- No sudo.

## Adopt

1. Copy `commit-signing-1password.sh` into your config's `steps/`.
2. Paste your public key into `SIGNING_KEY`.
3. Paste the `[[step]]` from `step.toml`. Keep `on-error = "warn"` so a machine
   without 1Password warns instead of failing the whole apply.
4. Upload the **same public key as a *Signing Key*** on your forge (GitHub:
   Settings → SSH and GPG keys → New SSH key → *Signing Key*) so the web shows
   "Verified".
5. First commit after this will pop a **1Password approval prompt** — approve it.

## Caveats

- **The `op-ssh-sign` path is macOS-App-Store-vs-direct-download-agnostic here**
  (`/Applications/1Password.app/…`) but assumes the standard install location. If
  your 1Password lives elsewhere, edit `OP_SSH_SIGN` in the script.
- **GUI-gated:** signing requires the 1Password app to be **running and
  unlocked**, and each signature may prompt for approval. On a headless box or
  over SSH with no GUI session, signing won't work — that's why the step uses
  `on-error = "warn"` and why the effect is manual-verify (see the test).
- `commit.gpgsign = true` makes **every** commit require a signature; if
  1Password is locked/quit, `git commit` fails until you unlock it (or use
  `--no-gpg-sign` for a one-off).
- 1Password also offers to auto-write this config for you. Adopting this recipe
  means kitout owns it instead; don't let both fight over `~/.gitconfig`.

## Security

**This delegates commit signing to 1Password — the posture is a step up from a
key file, with caveats.**

- **The private key never leaves 1Password.** Nothing here reads, exports, or
  writes a private key; `user.signingkey` holds only the **public** key. Signing
  happens inside 1Password's process (`op-ssh-sign`), gated by your vault lock and
  whatever approval you've configured (Touch ID / prompt). This is the main win
  over a plain on-disk key.
- **What a signature proves — and doesn't.** A signature attests the commit came
  from the holder of that key; it is **not** encryption and hides nothing. With
  1Password holding the key, "holder" means "whoever can unlock your 1Password and
  approve a signing request."
- **Trust boundary moves to 1Password + the helper path.** You're trusting the
  `op-ssh-sign` binary at the configured path to be the genuine 1Password helper.
  The recipe uses the app-bundle path 1Password itself installs; if an attacker
  could replace that binary they'd already have code-exec on your machine. Keep
  1Password updated and the app in `/Applications`.
- **No privilege, no network from this recipe.** It only writes user-scoped git
  config. 1Password's own agent handles the key material and any network is
  1Password's, not git's.
- **Reverse it:** `git config --global --unset commit.gpgsign` (and `tag.gpgsign`,
  `gpg.format`, `gpg.ssh.program`, `user.signingkey`). The key stays safe in your
  vault regardless.
