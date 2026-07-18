# hosts-block

Manage a small, user-editable ad/tracker **blocklist** in `/etc/hosts` — a
marked region kitout owns, sitting alongside whatever else is already there.

## What it does

Maintains a region in `/etc/hosts` between marker comments:

```
# >>> recipes:hosts-block >>>
0.0.0.0 example-tracker.com
# <<< recipes:hosts-block <<<
```

Each hostname in the region resolves to `0.0.0.0`, so any request to it fails
fast instead of reaching the network — the classic hosts-file ad/tracker-block
trick. The script keeps a `BLOCKLIST` array of hostnames; on every run it
renders the desired region and, only if it differs from what's on disk,
rebuilds the file: it `awk`s the old region out into a temp copy, appends the
freshly rendered region, and copies the result back over `/etc/hosts` with
`sudo`. Everything else in the file — `localhost`, `broadcasthost`, any other
entries — is preserved untouched.

The step's `check` (`grep -q 'recipes:hosts-block' /etc/hosts`) is a fast,
unprivileged presence probe; the script itself does the real content
comparison so re-running it when the list is unchanged is a no-op.

## Requirements

- `sudo = true` in your manifest — `/etc/hosts` is a root-owned system file;
  the script uses `sudo -A` with kitout's Keychain-backed askpass.
- No packages. `awk`, `cp`, `chmod` all ship with macOS.

## Adopt

1. Copy `hosts-block.sh` into your config's `steps/`.
2. Edit the `BLOCKLIST` array in the script to the hostnames you actually
   want to block. The shipped list is a single placeholder
   (`example-tracker.com`) — replace it.
3. Paste the `[[step]]` from `step.toml`. Ensure your manifest has
   `sudo = true`.

## Caveats

- **This is a blunt instrument, not a real ad blocker.** It only stops DNS
  resolution of the exact hostnames you list — no wildcard/regex matching, no
  auto-updated lists, no per-app scoping. For serious ad/tracker blocking use
  a maintained tool (e.g. a Pi-hole, NextDNS, or a browser extension) and
  treat this as a lightweight supplement.
- **A bad entry can break things.** Blocking the wrong hostname (a CDN a site
  actually needs, an API your tools call) will make that site or tool fail in
  confusing ways. Double-check anything you add.
- **The region gets rebuilt, not edited in place**, on every content change —
  if you'd hand-edited entries directly in `/etc/hosts` between the markers,
  those edits are overwritten by the script's `BLOCKLIST` (that's the point:
  the script, not the live file, is the source of truth). Edit the script,
  not the file.
- Set `HOSTS_FILE` in the environment to point the script at a different
  file — useful for testing; it defaults to the real `/etc/hosts`.

## Security

**Edits a SYSTEM file with root privilege — read this before adopting.**

- **What it changes:** appends/rebuilds one marked region in `/etc/hosts`,
  system-wide (every user and every process on the machine resolves through
  it, not just you).
- **Blast radius:** limited to name resolution for the hostnames you list.
  Done correctly, this only breaks reachability to the specific trackers you
  chose to block. Done carelessly (blocking a hostname something else
  depends on), it can silently break that app or site until you notice.
- **Privilege used:** `sudo cp` to replace `/etc/hosts` and `sudo chmod 644`
  to keep its standard permissions. No other system state is touched, nothing
  is downloaded, and no data is removed — only the marked region is added or
  rewritten.
- **Reversal:** delete the `# >>> recipes:hosts-block >>>` … `# <<< recipes:hosts-block <<<`
  region from `/etc/hosts` by hand (`sudo vi /etc/hosts`), or clear the
  `BLOCKLIST` array to an empty list and re-apply to shrink the region to
  just the markers.
