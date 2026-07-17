# commit-signing-ssh

Sign your git commits and tags with an **SSH key** — the modern, no-GPG path to
a "Verified" badge on GitHub/GitLab.

## What it does

Configures global git to sign with SSH (git **2.34+**, OpenSSH **8.2+**):

| Key | Value | Why |
|---|---|---|
| `gpg.format` | `ssh` | sign with an SSH key, not GPG |
| `user.signingkey` | your **public** key path | which key to sign with |
| `commit.gpgsign` | `true` | sign every commit |
| `tag.gpgsign` | `true` | sign annotated tags too |
| `gpg.ssh.allowedSignersFile` | `~/.config/git/allowed_signers` | enables local verification |

It also appends a line to `~/.config/git/allowed_signers` mapping your email to
the key, so `git log --show-signature` verifies **offline** (git can't otherwise
tell which keys are trusted). Point `user.signingkey` at the **public** key
(`.pub`) — git and forges only need the public half; the private key stays in
`~/.ssh` (or an agent).

The step's `check` is satisfied once `gpg.format=ssh` and `commit.gpgsign=true`,
and every write is compared first, so re-applying is a no-op.

## Requirements

- **git 2.34+ and OpenSSH 8.2+** (both ship on current macOS).
- An existing SSH key (`ssh-keygen -t ed25519` if you don't have one).
- `user.email` set in git (the script uses it as the signer principal), or edit
  `SIGNER_EMAIL` in the script.
- **Edit `SIGNING_KEY` and `SIGNER_EMAIL`** at the top of `commit-signing-ssh.sh`
  before adopting — the defaults assume `~/.ssh/id_ed25519.pub` and your git
  `user.email`.
- No sudo.

## Adopt

1. Copy `commit-signing-ssh.sh` into your config's `steps/`.
2. Edit `SIGNING_KEY` / `SIGNER_EMAIL` to your key and identity.
3. Paste the `[[step]]` from `step.toml`.
4. After applying, **upload the public key as a signing key** on your forge
   (GitHub: Settings → SSH and GPG keys → New SSH key → type *Signing Key*) — the
   local config alone won't show "Verified" on the web until the forge knows the
   key.

## Caveats

- **`commit.gpgsign = true` makes every commit require the key.** If the key
  lives in an agent that isn't running (or a hardware key that's unplugged),
  `git commit` fails until it's available. Use `--no-gpg-sign` for a one-off, or
  set `commit.gpgsign false` per-repo where signing isn't wanted.
- Uploading the **same** key as both an *auth* key and a *signing* key on GitHub
  is allowed but they're separate entries — add it under "Signing Key" too.
- This is global config; a repo can override `user.signingkey`/`commit.gpgsign`
  for a different identity (e.g. work vs personal).

## Security

**This wires a key into your commit workflow — read before adopting.**

- **Only the public key is referenced.** `user.signingkey` and the
  `allowed_signers` entry contain your **public** key; the private key is never
  read, copied, or moved by this recipe. Signing itself is done by `ssh-keygen`
  reaching into `~/.ssh` or your ssh-agent at commit time.
- **What a signature proves — and doesn't.** A signature attests the commit was
  made by whoever holds the private key; it is **not** encryption and hides
  nothing. Anyone with your private key can forge your signature, so the usual
  key hygiene applies (passphrase-protect it, prefer an agent or hardware key,
  don't commit the private key).
- **`allowed_signers` is a local trust store.** The recipe adds only *your own*
  email→key mapping, used purely for local `--show-signature` verification. It
  grants no remote access and trusts no one else. Adding other people's keys
  there (to verify their commits) is a deliberate, separate act.
- **No privilege, no network.** Everything is user-scoped git config plus one
  file under `~/.config/git/`. Nothing is downloaded; nothing runs as root.
- **Reverse it:** `git config --global --unset commit.gpgsign` (and
  `tag.gpgsign`, `gpg.format`, `user.signingkey`, `gpg.ssh.allowedSignersFile`),
  and remove your line from `~/.config/git/allowed_signers`.
