# custom-dns

Set the **DNS resolvers** for a network service (Wi-Fi, Ethernet, …) to a
fixed list — e.g. Cloudflare's `1.1.1.1` / `1.0.0.1`.

## What it does

Runs `networksetup -setdnsservers "$SERVICE" $DNS`, which pins that network
service's DNS resolution to exactly the servers you list (in order),
overriding whatever DHCP handed out. The step's `check` compares
`networksetup -getdnsservers "$SERVICE"` against the desired list, so it's
idempotent — once set, re-applying is a no-op.

Two variables, both overridable via the environment:

| Var | Default | Meaning |
|---|---|---|
| `SERVICE` | `Wi-Fi` | Network service name, exactly as `networksetup -listallnetworkservices` prints it |
| `DNS` | `1.1.1.1 1.0.0.1` | Space-separated resolver IPs, in priority order |

## Requirements

- `sudo = true` in your manifest — `networksetup -setdnsservers` is
  privileged; the script uses `sudo -A` with kitout's askpass. (Reading the
  current servers is unprivileged.)
- No packages. `networksetup` ships with macOS.

## Adopt

1. Run `networksetup -listallnetworkservices` and confirm your service's
   exact name (case- and space-sensitive — "Wi-Fi", not "wifi" or "WiFi").
2. Edit `SERVICE`/`DNS` at the top of `custom-dns.sh` if you're not using the
   defaults, and copy it into your config's `steps/`.
3. Paste the `[[step]]` from `step.toml` — **update the service name inside
   its `check` too** if you changed `SERVICE`, so `plan`/`status` stay honest.
4. Ensure your manifest has `sudo = true`.

## Caveats

- **The service name varies per Mac** — a MacBook usually has `Wi-Fi`, a Mac
  mini/Studio often has `Ethernet` or a specific adapter name, and VPN/VM
  tooling can add virtual services. `on-error = "warn"` is set for exactly
  this reason: a mismatched name shouldn't fail your whole `apply`.
- Reconnecting to a different Wi-Fi network doesn't change these settings —
  they're per-service, not per-SSID, so the resolvers stick across networks
  on the same service.
- Some networks (captive portals, corporate VPNs) expect you to use *their*
  DNS; pinning your own can break portal login or internal name resolution
  until you switch it back.

## Security

**This routes ALL DNS lookups for the chosen service through the resolver you
pick — read this before choosing one.**

- **What it changes:** every hostname lookup made over that network service —
  every app, every browser tab, every background process — now asks your
  chosen resolver instead of the network's default (usually your ISP or
  router).
- **Privacy/routing implications are the whole point of this step.** Whoever
  runs the resolver you pick sees every hostname you look up (not the page
  content, but the domains) unless you also use DoH/DoT some other way.
  **Only point this at a resolver you actually trust** — Cloudflare
  (`1.1.1.1`), Google (`8.8.8.8`), Quad9 (`9.9.9.9`), or your own, per your
  own threat model. This recipe ships Cloudflare's `1.1.1.1`/`1.0.0.1` as a
  reasonable, widely-used default — swap it if you prefer differently.
- **Privilege used:** one `sudo networksetup -setdnsservers` call. No other
  system state changes; nothing is downloaded.
- **Reversal:** `networksetup -setdnsservers "$SERVICE" Empty` restores
  automatic (DHCP-provided) DNS for that service.
