# shared-skills-dirs

One shared home for agent **skills** — drop a skill once, every coding agent sees it.

## What it does

Different coding agents look for "skills" (reusable, self-contained instruction
folders) in their own directories — Claude in `~/.claude/skills`, Codex in
`~/.codex/skills`, and so on. This recipe makes a vendor-neutral
**`~/.agents/skills`** the single source of truth and **symlinks** each agent's
skills directory at it, so a skill you author or install once is visible to all of
them instead of being copied N times and drifting.

The `shared-skills-dirs.sh` script:

1. `mkdir -p ~/.agents/skills` (the neutral, real directory).
2. For each per-agent path (`~/.claude/skills`, `~/.codex/skills` by default),
   creates a symlink to the neutral dir — or, if a symlink already points there,
   leaves it. If the path already exists as a **real directory** (you populated it
   before), it is **left untouched** and the script prints a note rather than
   moving or clobbering it.

The step's `check` probes that the neutral dir exists and each managed link is in
place, so `plan`/`status` are honest and the script is skipped once converged.

Edit the `links` array in the script (and the matching paths in the `check`) to
cover exactly the agents you run.

## Requirements

None. Pure filesystem — `mkdir` and `ln` in your home directory. No packages, no
privilege, no network.

## Adopt

1. Copy `shared-skills-dirs.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. If you run agents other than Claude/Codex, add their skills paths to the
   `links` array in the script **and** to the `check` list in `step.toml` so the
   two stay in sync.

## Caveats

- **Pre-existing real directories are not migrated.** If `~/.claude/skills`
  already exists as a populated directory, the script won't turn it into a symlink
  (that would risk your content). Move its contents into `~/.agents/skills`
  yourself, delete the empty dir, and re-run to have it linked.
- **Symlinked skills dirs assume the agent follows symlinks.** Every agent tested
  here reads through a symlinked skills dir normally, but a future agent could
  refuse to; if one ignores its skills after this, unlink and use a real dir.
- The script keeps the `links` array and the `step.toml` `check` in lockstep by
  convention — if you edit one, edit the other, or the check will misreport.

## Security

Low blast radius, but it does create **symlinks**, so read this.

- **What it changes:** creates `~/.agents/skills` and makes `~/.claude/skills` /
  `~/.codex/skills` symlinks pointing at it. All inside your home directory; no
  privilege, no network, nothing downloaded.
- **Symlink safety:** the script only ever *creates* a symlink at a path that is
  absent or already the same symlink. It never follows an existing symlink to
  write through it, and it refuses to replace a real directory — so it cannot be
  tricked into clobbering data behind an unexpected link.
- **Shared surface:** because the dirs are now one directory, a skill placed there
  is trusted by **every** agent that reads it. Skills can contain instructions an
  agent will act on, so treat `~/.agents/skills` as trusted input: only put skills
  there you'd be comfortable any of your agents executing. That is the point of the
  recipe, but it is also its one real consideration.
- **Reverse it:** `rm` the symlinks (`rm ~/.claude/skills ~/.codex/skills`) to
  detach each agent, and/or `rm -rf ~/.agents/skills` to remove the shared store.
  Removing a symlink never deletes the neutral dir's contents.
