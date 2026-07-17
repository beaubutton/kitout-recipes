# git-maintenance

Enable git's **background maintenance** for a repo — `git maintenance start`
keeps large repos fast by repacking, prefetching, and building commit-graphs on a
schedule, so you never wait on a foreground `git gc`.

## What it does

Runs `git maintenance start` in a target repo. That does two things:

1. **Registers the repo** — adds its absolute path to the global
   `maintenance.repo` list and sets `maintenance.strategy = incremental` for it
   (if unset), since maintenance takes over the scheduled upkeep.
2. **Installs a per-user scheduler** — on macOS a **launchd** agent (no root)
   that runs `git maintenance run` on cadences: hourly *prefetch*, daily
   *incremental-repack* / *loose-objects* / *pack-refs*, and *commit-graph*
   upkeep. Under the `incremental` strategy the scheduled **`gc` task is
   disabled** — it's replaced by these cheaper, incremental tasks. (Note: this
   does *not* set `gc.auto = 0`; the on-demand auto-gc that runs during commit/
   fetch is left at its default and is unaffected by this recipe.)

`git maintenance` is **per-repo**, so this recipe manages **one** repo. By
default it targets the current directory; to target a specific repo, point
`REPO` at it (see **Adopt**). Add more `[[step]]`s — or loop in your own script —
for additional repos.

The step's `check` is satisfied once the repo's top-level path is in the global
`maintenance.repo` list, so `plan`/`status` are honest and re-applying is a
no-op — **provided the `check` and the script resolve to the same repo.** They
read `REPO` independently (there is no shared variable), so if you retarget one
you must retarget both, or the step will report Pending and re-run every apply.

## Requirements

- `git` **2.30+** (`git maintenance` landed in 2.29/2.30 and stabilized after).
- A real git repository at `REPO`. The default is the current directory — which
  only makes sense if you `cd` into the repo before running kitout. kitout does
  **not** `cd` for you, so for an unattended run you almost always want to set
  `REPO` to an absolute path.
- No sudo — the scheduler is a **user** launchd agent, not a system daemon.

## Adopt

1. Copy `git-maintenance.sh` into your config's `steps/`.
2. Choose the repo. The script and the `check` in `step.toml` both read
   `${REPO:-$PWD}` but share no variable, so retarget **both together**. Pick one:
   - **Export `REPO`** in the environment kitout runs in (e.g.
     `REPO="$HOME/Source/big-monorepo" kitout apply`). Both probes pick it up —
     nothing to edit.
   - **Or hardcode the path** by replacing `${REPO:-$PWD}` with an absolute path
     in *both* the script and the `check`.
3. Paste the `[[step]]` from `step.toml`.
4. For several repos, duplicate the step with different `id`s, and give each a
   distinct target (a per-step hardcoded path, since one exported `REPO` can't
   differ per step).

## Caveats

- **Per-repo, and it must exist at apply time.** If `REPO` points at a path that
  isn't a repo yet (e.g. cloned by a later step), order it with `needs` so the
  clone happens first, or the script exits with a clear error.
- **The scheduler runs in the background on git's cadence**, using CPU/IO
  periodically. On a laptop that's usually invisible; on a heavily constrained
  machine, know it's there. It only runs while you're logged in (launchd
  *agent*).
- Registering a repo **disables the *scheduled* `gc` task** (via
  `maintenance.strategy = incremental`) — maintenance owns packing now via
  incremental tasks. That's intended, not a bug. It does **not** change
  `gc.auto`, so ordinary on-demand auto-gc still behaves normally.
- The recipe doesn't touch git's *global* maintenance defaults or other repos.

## Security

Low, and worth being precise about.

- **No privilege.** `git maintenance start` installs a **user-level launchd
  agent** (`~/Library/LaunchAgents/…`), not a root LaunchDaemon. Nothing here runs
  as root; no sudo is requested.
- **What runs on the schedule is git itself.** The scheduled command is
  `git maintenance run` against your registered repo(s) — the same repacking/gc
  machinery you'd run by hand. It operates only on repos you registered, makes no
  network calls **except** `prefetch`, which fetches from the repo's **existing
  configured remotes** (no new remotes, no new endpoints — the same servers
  `git fetch` already talks to).
- **Blast radius is your object store.** Maintenance rewrites packfiles and
  builds auxiliary files (commit-graph, multi-pack-index); it does **not** alter
  refs, branches, or working-tree content, and is designed to be safe to
  interrupt. It won't delete unreachable objects you'd otherwise keep any more
  aggressively than normal gc.
- **Reverse it:** `git -C <repo> maintenance unregister` (removes it from the
  global `maintenance.repo` list and stops managing it); `git maintenance stop`
  removes the launchd scheduler entirely. `unregister` leaves the repo-local
  `maintenance.strategy` / `maintenance.<task>.schedule` keys behind; clear them
  with `git -C <repo> config --unset maintenance.strategy` (and the per-task
  keys) if you want a fully pristine config back. This recipe never touched
  `gc.auto`, so there's nothing to restore there.
