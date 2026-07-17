# gh-cli-config

Set sane [GitHub CLI](https://cli.github.com) (`gh`) defaults, idempotently.

## What it does

Runs:

| Command | Effect |
|---|---|
| `gh config set editor "${EDITOR:-vim}"` | your `$EDITOR` (falling back to `vim`) opens for commit messages, issue/PR bodies, etc., instead of `gh`'s built-in default |
| `gh config set git_protocol ssh` | `gh repo clone`/`gh` git operations use SSH remotes instead of HTTPS |
| `gh config set prompt enabled` | `gh` prompts interactively when you omit a flag it needs (the default; set explicitly so it's not left to chance) |
| `gh alias set prs "pr list --author @me"` | a `gh prs` shortcut for your own open PRs — **skipped if an alias named `prs` already exists** |

Each `gh config set` call is compared against the current value first (via
`gh config get`), so re-running is a no-op once converged. The `step.toml`
`check` is just `command -v gh` — it confirms the tool exists so the step
isn't marked pending forever on a machine without `gh`, but it does **not**
re-verify every config value; this is a "configure once, safe to
re-apply" step rather than a strict per-key convergence check (see Caveats).

## Requirements

- The **`gh`** binary on `PATH` (`brew install gh`). Point the step's
  `needs` at your install step; `on-error = "warn"` in `step.toml` means a
  missing `gh` won't abort the rest of your manifest.
- **`git_protocol ssh` assumes you already have an SSH key registered with
  GitHub** (see this cookbook's `ssh-key` and `ssh-config-github` recipes).
  Without one, `gh repo clone`/push over the SSH remote will fail even
  though `gh` itself is configured correctly.
- No sudo.

## Adopt

1. Copy `gh-cli-config.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`; add
   `needs = ["<your gh install step>"]`.
3. After applying, `gh config list` to review, and try `gh prs`.

## Caveats

- **The step's `check` only confirms `gh` exists**, not that every setting
  is applied — because `gh config get` returns a built-in default (e.g.
  `https` for `git_protocol`) even when nothing has ever been set, so
  "already gh's default" and "explicitly configured by this step" are
  indistinguishable from a single read. In practice this just means the
  step runs (and no-ops quickly) on every `apply` rather than being skipped
  outright — harmless, since every action inside is itself idempotent.
- The `prs` alias is **additive only**: if you already have an alias named
  `prs` (yours or from another tool), this step leaves it alone rather than
  overwriting it. Rename or drop your existing one first if you want this
  recipe's definition.
- `gh` ships a few aliases of its own out of the box (e.g. `co` for `pr
  checkout`) — unrelated to this recipe, just don't be surprised to see them
  in `gh alias list`.
- This only touches `gh`'s own config (`~/.config/gh/config.yml`); it
  doesn't touch git's `user.*`, credential helper, or `core.editor` — those
  are separate (see `git-sensible-defaults`, `commit-signing-*`).

## Security

None — this is local CLI preference, not privilege or network access.

- **What it changes:** four keys in `~/.config/gh/config.yml`, plus one
  alias entry. No new authentication is granted or changed; `gh`'s existing
  auth (from `gh auth login`) is untouched by this recipe.
- **`git_protocol ssh` is a preference, not a credential change** — it just
  tells `gh` which remote URL scheme to use when it clones/adds a remote.
  It does nothing if you have no SSH key configured for GitHub (the
  operation will simply fail until you add one).
- **No privilege, no network calls beyond `gh`'s own config commands**
  (`gh config set`/`get`/`gh alias set` are all local file writes — they
  don't hit the GitHub API).
- **Reverse it:** `gh config set editor ""` / `git_protocol https` /
  `prompt enabled` (gh's defaults), and `gh alias delete prs`.
