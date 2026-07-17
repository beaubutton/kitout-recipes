# computer-name

Set the Mac's name consistently — macOS stores it in **three** places that can
drift apart, and this sets all of them.

## What it does

Runs `scutil --set` for:

| Field | Where you see it |
|---|---|
| `ComputerName` | Sharing settings, AirDrop, the friendly name |
| `HostName` | the network / DNS hostname |
| `LocalHostName` | the Bonjour `<name>.local` address |

The step's `check` compares `LocalHostName` to your chosen name, so it's idempotent.

## Requirements

- `sudo = true` in your manifest (`scutil --set` is privileged; the script uses
  `sudo -A` with kitout's askpass).
- No packages — `scutil` is built in.

## Adopt

1. Copy `computer-name.sh` into your config's `steps/`.
2. Set `NAME` in the script and the matching value in the step's `check`. Use a
   **hostname-safe** name — letters, digits, hyphens, no spaces (`LocalHostName`
   rejects spaces). If you want a pretty spaced `ComputerName`, set that one apart.
3. Paste the `[[step]]`.

## Caveats

- `LocalHostName`/`HostName` can't contain spaces or most punctuation.
- Some services cache the old name until a reboot.

## Security

Modest, but real: this name is **broadcast on local networks** — via Bonjour
(`<name>.local`), DHCP hostname, and AirDrop. On untrusted or public networks that's
a small information leak (it announces "this is `<name>`" to the LAN). Pick a name
you're comfortable advertising; avoid embedding personal identifiers if you roam
untrusted networks. Privilege is limited to three `scutil --set` calls; nothing is
downloaded. Reverse by setting a different name (or blank).
