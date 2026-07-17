# gitignore-global

Install a curated **global gitignore** (OS cruft, editor/IDE dirs, local-only
files) and point `core.excludesfile` at it — so `.DS_Store` and `.idea/` never
land in a project's own `.gitignore` again.

## What it does

Writes `~/.config/git/ignore` (git's XDG default location) with a curated set of
patterns, then sets `git config --global core.excludesfile` to that path. Every
repo you touch inherits these ignores on top of its own `.gitignore`.

Git already reads `~/.config/git/ignore` by default, but the script sets
`core.excludesfile` **explicitly** so behavior is deterministic even if you've
pointed `core.excludesfile` somewhere else or run an unusual `XDG_CONFIG_HOME`.

The list is deliberately about **your machine and tools**, not any one project:
macOS finder droppings (`.DS_Store`, `._*`), editor state (`.idea/`, `.vscode/`,
`*.swp`), and common tool caches. Edit the heredoc in `gitignore-global.sh` to
your taste — it's an opinion, not law.

Convergence lives in the script, not a `check` probe: whether this step is
"done" depends on the file's **content** matching the curated body, and a cheap
probe can't compare that without duplicating the body (and then drifting from
it). So the step ships without a `check` — `plan`/`status` always list it, and
`apply` runs the script, which does the exact content compare and rewrites only
when it differs. Repeat `apply` runs are true no-ops (the script prints
`already installed` and exits without touching anything), including after you
edit the heredoc — the next `apply` restores the curated body.

## Requirements

- `git` (any recent version). No brew formulae, no privilege.

## Adopt

1. Copy `gitignore-global.sh` into your config's `steps/` directory.
2. Paste the `[[step]]` from `step.toml` into your manifest.
3. Edit the heredoc in the script to add/remove patterns you care about.

## Caveats

- **A global ignore is invisible to teammates.** If a file needs to be ignored
  for *everyone* on a project, put it in the repo's `.gitignore`, not here — this
  list only affects your checkout.
- Global ignores can mask a file you actually want to add. `git add -f <path>`
  overrides an ignore when you really mean it.
- The script **owns the whole file** at `~/.config/git/ignore` — if you hand-edit
  that file, re-applying restores the curated body. Keep personal additions in
  the script's heredoc (which is the managed source of truth), not the file.

## Security

Low. Everything is user-scoped: it writes one file under `~/.config/git/` and one
key in your global `~/.gitconfig` — no privilege, no network, no execution of
anyone else's code.

The one thing worth stating plainly: a global ignore changes what `git status`
and `git add .` **show you**, so an over-broad pattern could hide a file you meant
to commit (never the reverse — it can't add or leak anything). The shipped list is
conservative and scoped to machine/tool cruft. Reverse it by removing
`~/.config/git/ignore` and running `git config --global --unset core.excludesfile`.
