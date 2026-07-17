# commit-signing-gpg

Sign your git commits and tags with a **GPG key** — the classic path to a
"Verified" badge on GitHub/GitLab, for people who already have (or want) a
GPG identity.

## What it does

Configures global git to sign with GPG:

| Key | Value | Why |
|---|---|---|
| `user.signingkey` | your key's ID | which key to sign with |
| `commit.gpgsign` | `true` | sign every commit |
| `tag.gpgsign` | `true` | sign annotated tags too |
| `gpg.program` | `$(command -v gpg)` | which `gpg` binary git shells out to |

This is the **GPG alternative** to the `commit-signing-ssh` and
`commit-signing-1password` recipes in this cookbook — pick one signing
mechanism, not all three. Prefer this one if you already manage a GPG
identity (e.g. also used for signed release tarballs or encrypted email);
prefer SSH signing if you'd rather reuse a key you already have for auth and
skip GPG's key-management overhead entirely.

The step's `check` is satisfied once `commit.gpgsign=true`, and every write
is compared first, so re-applying is a no-op.

## Requirements

- **A GPG key.** If you don't have one: `gpg --full-generate-key` (pick
  RSA/ed25519, a real name/email, a passphrase).
- **`gpg` on PATH** (`brew install gnupg`).
- **Edit `KEYID`** at the top of `commit-signing-gpg.sh` to your key's ID —
  find it with `gpg --list-secret-keys --keyid-format long` (the ID follows
  `rsa4096/` or `ed25519/` on the `sec` line). Left as the placeholder, the
  script fails loudly with these exact instructions rather than silently
  doing nothing.
- `step.toml` sets `on-error = "warn"` because this step is expected to fail
  until you've both installed gpg and generated/edited in a real key — that
  shouldn't abort the rest of your manifest.
- No sudo.

## Adopt

1. Copy `commit-signing-gpg.sh` into your config's `steps/`.
2. Generate a key if needed, then edit `KEYID` in the script to match.
3. Paste the `[[step]]` from `step.toml`.
4. After applying, **upload your public key** to your forge (GitHub:
   Settings → SSH and GPG keys → New GPG key; `gpg --armor --export KEYID`
   gives you the block to paste) — local config alone won't show "Verified"
   on the web until the forge has the public key.

## Caveats

- **`commit.gpgsign = true` makes every commit require the key** (and, if
  the key has a passphrase, a `pinentry` prompt — the first commit in a
  session will pause for it, cached thereafter per your `gpg-agent`
  settings). Use `--no-gpg-sign` for a one-off, or set `commit.gpgsign
  false` per-repo where signing isn't wanted.
- GPG key **expiry**: keys generated with an expiration will silently stop
  signing (or signing will start failing verification) once they lapse —
  check `gpg --list-keys` for the `expires` field and extend it
  (`gpg --edit-key KEYID` → `expire`) before it does.
- This is global config; a repo can override `user.signingkey`/
  `commit.gpgsign` for a different identity (e.g. work vs personal) — see
  the `git-conditional-identity` recipe for a directory-scoped identity
  switch you could pair this with.

## Security

**This wires a private key into your commit workflow — read before adopting.**

- **What's referenced:** only the key **ID** (`user.signingkey`) is written
  to git config; the private key material lives in your GPG keyring
  (`~/.gnupg`) and is never read, copied, or moved by this script. Signing
  itself happens via `gpg` at commit time, using whatever unlock mechanism
  your `gpg-agent` is configured with (passphrase prompt, cached agent, or a
  hardware token if your key is on one).
- **What a signature proves — and doesn't.** A signature attests the commit
  was made by whoever controls the private key; it is **not** encryption
  and doesn't hide the commit's contents. Anyone who obtains your private
  key (and passphrase, if set) can forge your signature — the usual GPG key
  hygiene applies: strong passphrase, consider a hardware token
  (YubiKey/smart card), back up the key materal securely, set an expiry.
- **No privilege, no network.** Everything here is user-scoped git config
  plus a `command -v gpg` lookup. Nothing is downloaded; nothing runs as
  root. The one exception is if you choose to publish your public key to a
  forge (step 4 of Adopt) — that's a public key, safe to share by design.
- **Reverse it:** `git config --global --unset commit.gpgsign` (and
  `tag.gpgsign`, `user.signingkey`, `gpg.program`). To retire the key
  itself: revoke it (`gpg --gen-revoke KEYID`) and remove it from your forge
  account and keyring.
