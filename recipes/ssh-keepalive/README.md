# ssh-keepalive

Stop idle **SSH sessions from dropping** — a `Host *` block with keepalive
settings, appended to the end of `~/.ssh/config`.

## What it does

Uses kitout's `block-in-file` step to manage a marked region at the **end**
of `~/.ssh/config` (`# >>> recipes:ssh-keepalive >>>` … `# <<< recipes:ssh-keepalive <<<`,
using `#` comments — valid `ssh_config` syntax) containing:

```
Host *
  ServerAliveInterval 60
  ServerAliveCountMax 3
  TCPKeepAlive yes
```

- `ServerAliveInterval 60` — the client asks the server for a response every
  60 idle seconds.
- `ServerAliveCountMax 3` — after 3 unanswered keepalive requests (~3 minutes)
  the client gives up and closes the connection, instead of hanging forever.
- `TCPKeepAlive yes` — also enables the underlying TCP-level keepalive (the
  default, made explicit here).

Together these keep a session alive through NAT/firewall idle timeouts and
flaky networks, while still detecting and closing a genuinely dead connection
in a few minutes rather than hanging silently.

**Why this has to be a `Host *` block at the *end* of the file:**
`ssh_config` is **first-match-wins** — for any given option, the first `Host`
pattern that matches the target and sets that option wins, and later blocks
setting the same option are ignored. A `Host *` matches every host, so if it
came first it would win for everything and no earlier, more specific block
could override these three settings. `block-in-file` **appends** a new block
(and rewrites it in place on later changes), which is exactly the placement
this needs — don't manually relocate it above your other `Host` entries.

## Requirements

- OpenSSH (`~/.ssh/config` support) — ships with macOS.
- No packages, no privilege, no network.

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest, `kitout apply`.
2. Make sure `~/.ssh/config` is **`chmod 600`** — OpenSSH silently ignores (or
   some versions refuse) a config file that's group/world-readable/writable:
   `chmod 600 ~/.ssh/config`. If the file doesn't exist yet, kitout creates it
   when it writes the block, but the permissions kitout sets may not match
   OpenSSH's expectations on every system — check after the first apply.

## Caveats

- **Must stay last.** If you add more `Host` blocks to `~/.ssh/config` later,
  add them *above* this managed region (or re-run `kitout apply`, which
  rewrites the region in place — it won't move it back to the end for you if
  you've since appended something after it by hand).
- Only affects the SSH **client** side (your outgoing connections). It says
  nothing about `sshd` on machines you connect *to* — those have their own
  `ClientAliveInterval`/`ClientAliveCountMax` in `/etc/ssh/sshd_config` if you
  also want the server side to probe.
- Timings are a starting point (idle-drop in ~3–4 minutes of total
  unresponsiveness); tighten `ServerAliveCountMax` if you want faster failure
  detection, or lengthen the interval on very high-latency links.

## Security

**None** — this changes only client-side connection timing, nothing about
authentication, trust, or what hosts you connect to.

- **What it changes:** three keepalive-related directives in a `Host *`
  block. Nothing about ciphers, host-key verification, forwarding, or
  authentication is touched.
- **No privilege, no network, no data removed.** The recipe only edits your
  own `~/.ssh/config`.
- **Reversal:** delete the `# >>> recipes:ssh-keepalive >>>` … `# <<< recipes:ssh-keepalive <<<`
  region from `~/.ssh/config`.
