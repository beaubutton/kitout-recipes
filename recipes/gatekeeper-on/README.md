# gatekeeper-on

Ensure **Gatekeeper** is enabled — the safe direction only. This recipe never
disables Gatekeeper.

## What it does

Runs `spctl --master-enable`, the CLI equivalent of Gatekeeper's "App Store
and identified developers" setting (System Settings → Privacy & Security).
With Gatekeeper on, macOS checks code-signing and notarization before running
an app you downloaded, and blocks/warns on anything unsigned or
unnotarized unless you explicitly override it (right-click → Open, or
`xattr`/`spctl` for a specific app). The step's `check` reads `spctl --status`
(unprivileged) for `assessments enabled`, so `plan`/`status` are honest and the
script is a fast no-op once already enabled.

## Requirements

- Any modern macOS (`spctl` is built in).
- `sudo = true` in your manifest — `--master-enable` needs admin. kitout
  exposes `SUDO_ASKPASS`; the script uses `sudo -A` so `apply -y` runs
  unattended. (Reading status is unprivileged; only the *enable* call
  escalates.)

## Adopt

1. Copy `gatekeeper-on.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`. Keep `on-error = "warn"`.
3. Ensure your manifest has `sudo = true`.

## Caveats

- **This recipe is one-directional by design** — it only ever enables
  Gatekeeper. There is no companion "disable" step here; disabling Gatekeeper
  is something you should do knowingly and manually (see Security below), not
  via a bootstrap recipe.
- **Recovery-mode requirement on some configurations.** Certain macOS releases
  and security-policy states (especially on Apple Silicon with a reduced or
  permissive security policy) don't allow `spctl --master-enable` to change
  Gatekeeper's state from a running OS at all — some or all of that control
  has moved to **Recovery mode** → Startup Security Utility, or requires
  reducing the security policy first. If the script prints the "may require
  Recovery mode" message, that's what's happening: boot into Recovery
  (Intel: hold Cmd+R; Apple Silicon: hold the power button) and check Startup
  Security Utility / Security Policy for the relevant toggle.
- `on-error = "warn"` is set specifically for that Recovery-mode case, so a
  Mac that needs a Recovery-mode change warns instead of failing your whole
  `apply`.

## Security

**This raises your security posture — the safe direction, with no downside
blast radius from this recipe.**

- **What it changes:** re-enables macOS's gate on running unsigned/
  unnotarized downloaded software without an explicit, deliberate user
  override. It does not quarantine, delete, or touch any existing app —
  already-installed software keeps running; this only affects the check that
  runs the *next* time you open something newly downloaded.
- **Blast radius:** system-wide (all users), but purely a policy gate — no
  files are modified, no network calls are made, nothing is removed.
- **Privilege used:** `sudo spctl --master-enable`. Nothing else is touched.
- **Reverse it (do this knowingly, not accidentally):** `sudo spctl
  --master-disable` turns Gatekeeper back off, System Settings-side. Disabling
  Gatekeeper materially increases risk — it removes the safety net that stops
  most opportunistic malware from running with a double-click — so treat that
  reversal as a deliberate, informed choice, ideally temporary (e.g. to test an
  unsigned build), not a standing configuration.
- **Recovery-mode note:** on configurations where enabling requires Recovery
  mode (see Caveats), the Startup Security Utility toggle there is the
  authoritative control; `spctl` merely reflects/attempts to match it from
  inside the running OS.
