# 1password-ssh-agent

Route SSH authentication through the **1Password SSH agent** so your keys live in
your 1Password vault (Touch-ID / device-unlock gated) instead of on disk.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.ssh/config`
(`# >>> recipes:1password-agent >>>` … `# <<< recipes:1password-agent <<<`) that
sets `IdentityAgent` to 1Password's agent socket:

```
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

After this, `ssh` asks the 1Password agent (not `ssh-agent`) which keys to offer;
1Password prompts you (Touch ID / Apple Watch / password) to approve each use. Keys
stored as SSH-key items in your vault are served without ever writing a private key
to `~/.ssh`. Everything outside the markers stays yours — kitout only rewrites the
block. No script.

## Requirements

- **1Password 8** (desktop app) with the **SSH agent enabled**:
  Settings → Developer → *Use the SSH agent*. That toggle is what creates the socket.
- macOS. The socket path is 1Password's macOS default (the `2BUA8C4S2C` team prefix
  is 1Password's; it's the same for everyone). On Linux the path differs
  (`~/.1password/agent.sock`) — adjust the block.
- No sudo.

## Adopt

1. Enable the SSH agent in the 1Password app first (see Requirements) — the socket
   must exist for SSH to connect to it.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. `kitout apply`, then test with `SSH_AUTH_SOCK` unset: `ssh -T git@github.com`
   should trigger a 1Password approval prompt.

## Caveats

- **A `Host *` block sets the default agent for *every* host.** If you already run
  another agent (plain `ssh-agent`, `gpg-agent`, a corporate one), this overrides it
  for all hosts. Scope it to specific hosts (`Host github.com`) if you only want
  1Password for some.
- **`IdentityAgent` precedence:** the *first* matching `IdentityAgent` in
  `~/.ssh/config` wins. If you have an earlier `Host *` block setting a different
  agent, this one won't take effect — move it up or remove the conflicting one.
- If the 1Password app is quit, the socket goes away and SSH auth via it stops
  working until the app is running again.
- It does not import your existing on-disk keys into 1Password — do that in the app
  (or add them as SSH-key items) if you want them served by the agent.

## Security

**This changes where SSH gets your private keys — a meaningful posture change.**

- **Net effect is usually a hardening.** With the 1Password agent, private keys can
  live *only* in your encrypted vault and are **served, never exposed**: SSH gets a
  signature from the agent, not the key bytes. Each use is gated by a biometric /
  device-unlock approval, so a background process running as you can't silently sign
  with your key the way it can with a passphrase-cached `ssh-agent`.
- **What it trusts.** SSH now trusts a Unix-domain socket owned by the 1Password
  app. Anything that can talk to that socket while 1Password is unlocked can *request*
  signatures — but 1Password's per-use approval prompts are the gate. Keep the app's
  auto-lock tight.
- **The path is not a secret.** The `2BUA8C4S2C.com.1password` group-container path
  is 1Password's public bundle prefix, identical on every Mac — pointing at it
  discloses nothing. The socket is user-owned under your `~/Library`; other local
  accounts can't reach it.
- **No privilege, no network.** This only edits a marked block in your own
  `~/.ssh/config`. No sudo; nothing is downloaded.
- **Reverse it.** Delete the marked block (or remove the recipe and re-apply) and
  SSH falls back to on-disk keys / the default `ssh-agent`. Your vault keys are
  untouched.
