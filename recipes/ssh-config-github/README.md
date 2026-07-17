# ssh-config-github

Add a ready-to-use **`github.com` Host block** to `~/.ssh/config` and **pin
GitHub's ed25519 host key** in `~/.ssh/known_hosts` — so the first `git@github.com`
connection doesn't dump an unverified "authenticity of host" prompt on you.

## What it does

Two idempotent edits, in `~/.ssh/config` and `~/.ssh/known_hosts`:

1. **Host block** (managed between `# >>> recipes:github >>>` markers):

   ```
   Host github.com
     HostName github.com
     User git
     AddKeysToAgent yes
     IdentitiesOnly yes
     IdentityFile ~/.ssh/id_ed25519
   ```

   `IdentitiesOnly yes` stops SSH from offering every key in your agent to GitHub
   (which can trip GitHub's "too many auth failures" limit); it uses exactly the
   `IdentityFile` you name.

2. **Pinned host key** — appends GitHub's published `github.com ssh-ed25519 …` line
   to `~/.ssh/known_hosts`. The key is **hardcoded from GitHub's published list**,
   and the script **re-derives its SHA256 fingerprint with `ssh-keygen` and
   compares it to GitHub's published value before writing** — if they don't match
   (corrupted paste, tampering), it refuses to write and exits non-zero.

The step's `check` is satisfied only when *both* the config marker and the pinned
key line are present, so `plan`/`status` are honest and the script no-ops once done.

## Requirements

- OpenSSH (`ssh-keygen`) — ships with macOS.
- Pairs with the [`ssh-key`](../ssh-key) recipe: the Host block's `IdentityFile`
  points at `~/.ssh/id_ed25519`. Add `needs = ["ssh-key"]` so the key exists first
  (or edit the `IdentityFile` to your key's path).
- No sudo, no network.

## Adopt

1. Copy `ssh-config-github.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`. Add `needs = ["ssh-key"]` if you use that
   recipe.
3. `kitout apply`, then `ssh -T git@github.com` — you should get GitHub's greeting
   with **no** host-authenticity prompt.

## Caveats

- **Edits `~/.ssh/config` by appending a marked block.** If you already have a
  `Host github.com` block elsewhere in the file, SSH merges options top-down and the
  *first* value for each key wins — a conflicting earlier block can shadow this one.
  Check for duplicates.
- The pinned key is **ed25519 only**. If your client negotiates RSA/ECDSA for
  github.com (unusual with modern OpenSSH), you'd still get a prompt for that
  algorithm; add the corresponding published line if so.
- **Host keys can rotate.** GitHub rotates its host keys rarely (e.g. the 2023 RSA
  rotation after an exposure). If GitHub rotates the ed25519 key, this pinned line
  goes stale and you'll get a host-key-mismatch warning — see Security for how to
  refresh it safely.

## Security

**This pins a trust anchor for github.com — the verification is the point.**

- **Why pin at all.** TOFU ("trust on first use") means the very first connection
  blindly accepts whatever key answers — a MITM at that moment gets trusted forever.
  Pinning the *known-correct* key up front closes that window: a MITM presenting a
  different key now triggers SSH's loud host-key-mismatch error instead of a silent
  accept.
- **The key is verified, not blindly trusted.** The hardcoded line is re-hashed with
  `ssh-keygen -lf` and checked against GitHub's **published** fingerprint
  (`SHA256:+DiY3wvvV6TuJJhbpZisF/zLDA0zPMSvHdkr4UvCOqU`) before it's written. A
  wrong or tampered key can't be installed — the script aborts. You can confirm the
  same fingerprint yourself at
  [GitHub's SSH key fingerprints page](https://docs.github.com/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints).
- **Blast radius is `github.com` only.** It appends one host line to `known_hosts`
  and one Host block to `config`; it doesn't touch other hosts, and it never removes
  or overwrites an existing key for a different host.
- **No secrets, no privilege, no network.** Host keys are *public*. Nothing is
  downloaded (the key is pinned in the recipe, not fetched), no sudo is used, and
  your private key is never read or moved.
- **Reverse / refresh it.** Delete the marked block from `~/.ssh/config` and remove
  the `github.com` line from `~/.ssh/known_hosts`. If GitHub legitimately rotates
  the key, update `gh_hostkey`/`gh_fp_expected` in the script to the new published
  values (verify the new fingerprint on GitHub's page first) and re-apply.
