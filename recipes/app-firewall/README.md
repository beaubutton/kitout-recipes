# app-firewall

Enable macOS's built-in **application firewall** and **stealth mode**.

## What it does

Uses Apple's `socketfilterfw` control tool
(`/usr/libexec/ApplicationFirewall/socketfilterfw`) to:

- `--setglobalstate on` — turn on the **application-layer firewall (ALF)**, which
  filters *inbound* connections on a per-application basis.
- `--setstealthmode on` — stop the Mac from responding to unsolicited probes
  (e.g. ICMP `ping`, closed-port TCP), so it doesn't announce itself to scanners.

The step's `check` reads the current state with `--getglobalstate` /
`--getstealthmode` (both work unprivileged), so `plan`/`status` are honest and the
script is a fast no-op once both are on.

**This is not the `pf` packet filter.** ALF is an inbound, application-aware filter;
it does not do outbound filtering or NAT. It's the same control the Settings UI
exposes under Network → Firewall.

## Requirements

- Any modern macOS (the ALF tool has shipped for many releases).
- `sudo = true` in your manifest — changing firewall state needs admin. kitout
  exposes `SUDO_ASKPASS`; the script uses `sudo -A` so `apply -y` runs unattended.
  (Reading state is unprivileged; only the *set* calls escalate.)

## Adopt

1. Copy `app-firewall.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`.
3. Ensure your manifest has `sudo = true`.

## Caveats

- **Stealth mode has a real tradeoff:** the Mac stops replying to `ping` and to
  connections on closed ports. That's good against scanners but can confuse network
  diagnostics ("why won't this host ping?"). Drop the stealth line (and the
  `--getstealthmode` half of the `check`) if you want the firewall without it.
- ALF filters **inbound** only. It won't block a program you run from phoning home;
  for outbound control you want a separate tool (e.g. Little Snitch, or `pf`).
- Enabling the firewall may prompt (via the GUI, later) about specific apps
  accepting incoming connections — that's normal ALF behavior, not this step.

## Security

**This *raises* your security posture — but understand exactly what it does.**

- **What it changes:** two system firewall settings, on. It does not open ports,
  add exceptions, or allow anything new inbound — the default ALF policy is to
  block unsigned/unexpected inbound listeners and prompt on first bind.
- **Blast radius:** system-wide network policy (not user-scoped). Every app that
  tries to *accept* inbound connections is now subject to ALF. It does not touch
  outbound traffic, established connections, or loopback.
- **Stealth mode caveat (repeat):** by design the machine goes quiet to probes.
  On a managed/monitored network where something *expects* to ping this host, that
  can look like an outage. Know your environment.
- **Privilege used:** `sudo socketfilterfw --setglobalstate on` and
  `--setstealthmode on`. Nothing is downloaded; no other system state is touched.
- **Reverse it:** `sudo /usr/libexec/ApplicationFirewall/socketfilterfw
  --setglobalstate off` (and `--setstealthmode off`), or toggle it in
  System Settings → Network → Firewall.
