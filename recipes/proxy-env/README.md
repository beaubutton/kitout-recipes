# proxy-env

Seed **proxy environment-variable placeholders** into `~/.zshrc` — commented
out until you fill in a proxy URL — plus an active `no_proxy` exemption for
local/loopback addresses.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:proxy-env >>>` … `# <<< recipes:proxy-env <<<`) containing:

```sh
# Uncomment and set these to point your shell at a proxy you trust:
# export http_proxy="http://user:pass@proxy.example.com:8080"
# export https_proxy="http://user:pass@proxy.example.com:8080"
# export all_proxy="socks5://proxy.example.com:1080"
# export HTTP_PROXY="$http_proxy"
# export HTTPS_PROXY="$https_proxy"
# export ALL_PROXY="$all_proxy"
export no_proxy="localhost,127.0.0.1,::1,*.local"
export NO_PROXY="$no_proxy"
```

Everything except `no_proxy`/`NO_PROXY` ships **commented out** — this recipe
only scaffolds the variable names most CLI tools already respect
(`curl`, `git`, `npm`, `pip`, many language runtimes), it does not point you
at any proxy. The lowercase and uppercase pairs are both included because
tools are inconsistent about which case they read.

`no_proxy`/`NO_PROXY` is the one line shipped **active**: it exempts
loopback and `.local` addresses from proxying, so that once you do turn a
proxy on, things like a local dev server or `*.local` mDNS hosts don't
suddenly route through it too.

## Requirements

- A zsh login shell. For bash/fish, adapt the target file accordingly.
- Nothing to install — this is pure shell `export`s, no binary, no package.

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest, `kitout apply`.
2. Open a new shell, edit `~/.zshrc` **inside the managed block** (or edit the
   `block` in `step.toml` and re-apply) to uncomment and fill in the proxy
   lines you actually need — see Security before picking a proxy URL.
3. Open a new shell to pick up the exports.

## Caveats

- **Takes effect in new shells**, not the one that ran the apply.
- Shipped inactive by design — until you uncomment lines and re-apply (or
  hand-edit inside the markers), this recipe changes nothing about how your
  shell makes network requests.
- Not every tool respects these variables the same way — some read only
  lowercase, some only uppercase, some (e.g. Docker daemon, some GUI apps)
  need proxy config in a completely different place. Treat this as covering
  typical CLI tools, not a system-wide proxy switch.
- If you edit the block directly in `~/.zshrc` rather than in `step.toml`,
  remember the next `kitout apply` **rewrites the whole managed region** from
  the manifest — keep the two in sync, or edit only the manifest.

## Security

**Env vars only — but a proxy you point these at can see and alter your
traffic. Read this before uncommenting anything.**

- **What this step changes, as shipped:** one active pair of `no_proxy`
  exemptions and six commented-out placeholder lines. No network behavior
  changes until you uncomment something.
- **Once you fill in and enable a proxy URL:** you are telling every proxy-
  aware tool in new shells to route its HTTP/HTTPS/SOCKS traffic through that
  endpoint. **Only point this at a proxy you control or explicitly trust** —
  a forward proxy (especially one doing TLS interception / MITM, common for
  corporate proxies) can read, log, or modify traffic that passes through it,
  including anything not using certificate pinning. Never paste credentials
  into a proxy URL for a proxy you don't trust with them.
- **Credentials in the URL are visible in plaintext** in `~/.zshrc` and in
  your shell's environment (visible to any process you run, and to `env`/`ps`
  in some configurations) if you use the `user:pass@` form. Prefer a
  credential-free proxy or a secrets manager if that's a concern.
- **No privilege, no system files.** This only edits your own `~/.zshrc`;
  nothing is downloaded and no data is removed.
- **Reversal:** remove the block from `~/.zshrc`, or re-comment/blank the
  lines you'd filled in and open a new shell.
