# ssh-key

Generate a personal **ed25519** SSH key if you don't have one, then load it into
the ssh-agent and stash its passphrase in the macOS login Keychain.

## What it does

- Checks for `~/.ssh/id_ed25519`. If it's missing, runs `ssh-keygen -t ed25519`
  **interactively** so you choose the passphrase yourself — the recipe never bakes
  in an empty one (`-a 100` sets a strong KDF work factor for the on-disk key). It
  **refuses to generate unless stdin is a terminal** (a non-TTY prompt would answer
  the passphrase empty and write an unencrypted key), and it **deletes any key that
  ends up with an empty passphrase** rather than leave a plaintext secret on disk.
- Fixes the permissions (`~/.ssh` → 700, private key → 600, `.pub` → 644).
- Adds the key to the running agent with `ssh-add --apple-use-keychain`, which also
  saves the passphrase to your **login Keychain** so you're not re-prompted every
  session. On a non-Apple `ssh-add` it falls back to a plain `ssh-add`.

The step's `check` probes for the private key, so `plan`/`status` show it satisfied
once the key exists and the generate step is skipped. Re-running only re-adds the
key to the agent (a no-op if already loaded).

Override the key comment with `SSH_KEY_COMMENT` (defaults to `user@host`).

## Requirements

- macOS (for `--apple-use-keychain`). Works on Linux too, minus the Keychain
  integration (falls back to a plain agent add).
- Nothing to install — `ssh-keygen`/`ssh-add` ship with OpenSSH.
- No sudo.

## Adopt

1. Copy `ssh-key.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`.
3. Run `kitout apply`. **The first run is interactive** — answer the passphrase
   prompt. Subsequent runs are silent no-ops.

## Caveats

- **First run needs a terminal you can type into** — `ssh-keygen` blocks on the
  passphrase prompt. In a headless/unattended context (piped stdin, CI, a detached
  runner) the step **fails fast** instead of generating a key: a non-interactive
  passphrase prompt would silently produce an *unencrypted* key, so the recipe
  refuses rather than do that. (This is on purpose: see Security.)
- It generates a *new* key; it does not import or migrate an existing key from
  another machine. If you already have a key elsewhere, copy it in instead of
  running this.
- The agent-load and Keychain save happen in the session that runs the script;
  they persist across reboots via the Keychain, but a fresh agent may need one
  `ssh-add --apple-use-keychain ~/.ssh/id_ed25519` after a cold boot (macOS usually
  does this automatically when `UseKeychain yes` is in your `~/.ssh/config`).

## Security

**This creates a long-lived credential — the passphrase choice is the whole game.**

- **Use a passphrase. Do not leave it empty.** An unencrypted private key is a
  plaintext secret: anyone who reads `~/.ssh/id_ed25519` (a stray backup, a synced
  folder, a compromised process running as you) gets your identity outright. With a
  passphrase, the on-disk key is useless without it. This recipe **refuses to
  automate the passphrase** precisely so you can't accidentally ship an empty one —
  that's why the first run is interactive. Two guards enforce this: it **won't
  generate at all unless stdin is a real terminal** (omitting `-N` only guarantees a
  *prompt*, and a non-TTY prompt is answered empty — so a bare TTY check is the part
  that actually holds the line), and after generation it **verifies the key carries a
  passphrase and deletes it if not**. There is no code path that leaves an empty-
  passphrase key on disk.
- **What the Keychain save means.** `--apple-use-keychain` stores the passphrase in
  your **login Keychain**, which is itself encrypted and unlocked by your macOS
  login password. This is the right tradeoff: strong at-rest protection for the key
  file, convenience via the Keychain. It does mean anyone who can unlock your Mac
  (your login password, or a session you left unlocked) can use the key — so pair
  this with a locking screen (see the `lockscreen-immediate` recipe).
- **Permissions are enforced.** The script chmods `~/.ssh` to 700 and the private
  key to 600 so other local accounts can't read it; OpenSSH refuses to use a
  world-readable key anyway.
- **No network, no privilege.** Nothing is uploaded — the **public** key
  (`~/.ssh/id_ed25519.pub`) is what you paste into GitHub/servers; the private key
  never leaves the machine. No sudo is used.
- **Reverse it.** Remove the key from the agent with `ssh-add -d ~/.ssh/id_ed25519`,
  delete the Keychain entry (`SSH: <key>` in Keychain Access), and `rm` the key
  pair. Revoke it anywhere you registered the public half.
