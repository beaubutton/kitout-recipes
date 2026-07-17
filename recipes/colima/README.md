# colima

Start [Colima](https://github.com/abiosoft/colima) as your local Docker runtime —
a free, CLI-only alternative to Docker Desktop.

## What it does

Runs `colima start` (with sensible CPU/memory/disk sizing) to boot a Lima-backed
Linux VM that runs the Docker daemon and exposes a Docker socket. After it's up,
`docker` and `docker compose` work exactly as they would against Docker Desktop —
Colima registers a `colima` Docker context and points the CLI at it.

The step's `check` is `colima status`, which exits 0 only when the default
profile's VM is running, so `plan`/`status` are honest and the script exits fast
once the VM is up (it does **not** reboot a running VM).

## Requirements

- The `colima` and `docker` CLIs (macOS: `brew "colima"`, `brew "docker"`). The
  `docker` formula is the client only — Colima provides the daemon. Point the
  step's `needs` at whatever installs them.
- Virtualization support: Apple Silicon or an Intel Mac with virtualization
  enabled (the default). No admin rights needed — Colima runs entirely in
  user space.

## Adopt

1. Copy `colima.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. Adjust `--cpus` / `--memory` / `--disk` in the script to fit your machine and
   workloads, then `kitout apply`.
4. Confirm with `docker context ls` (you should see `colima`) and `docker ps`.

## Caveats

- **First boot is slow** (a minute or two) and downloads a VM image; later runs
  are instant no-ops.
- **Resizing** CPU/memory/disk after first boot needs `colima stop` then
  `colima start` with new flags — editing the script alone won't resize a
  VM that already exists.
- It manages the **default** Colima profile only. If you run named profiles
  (`colima start -p work`), adapt the script and the `check` (`colima status -p work`).
- Colima must be started again after a reboot (or logout) — it isn't a launch
  daemon. Re-running the step (or `kitout apply`) brings it back up.

## Security

**Local-only, no privilege — but understand what a Docker daemon is.**

- **No sudo, no system files.** Colima and its VM run entirely in your user
  account under `~/.colima` and `~/.lima`. This recipe never uses `sudo`.
- **Network:** first boot downloads a VM image and guest packages over HTTPS from
  the Colima/Lima projects; steady-state it's a local VM with a local socket.
- **What running a Docker daemon means:** any process that can reach the Docker
  socket can start containers, mount host paths you expose, and run code inside
  the VM. That's inherent to Docker, not specific to Colima — treat the Docker
  socket as a trust boundary and be deliberate about `-v` host mounts. Colima is
  actually *less* privileged than Docker Desktop here: no root helper, no
  privileged background service.
- **Reverse it:** `colima stop` shuts the VM down; `colima delete` destroys it and
  its disk. `brew uninstall colima` removes the tool.
