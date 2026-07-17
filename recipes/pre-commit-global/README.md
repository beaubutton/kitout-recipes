# pre-commit-global

Make every **future** `git init`/`git clone` install
[pre-commit](https://pre-commit.com)'s hooks automatically — no more
forgetting `pre-commit install` in a fresh clone.

## What it does

Uses git's **template directory** mechanism:

```
pre-commit init-templatedir ~/.config/git/template
git config --global init.templateDir ~/.config/git/template
```

`pre-commit init-templatedir` writes a small hook stub for every hook type
pre-commit supports (pre-commit, pre-push, commit-msg, …) into that
directory. Git, on every `init`/`clone`, copies the contents of
`init.templateDir` into the new repo's `.git/`. So any repo you create or
clone **from now on** already has pre-commit's stubs wired in — and each
stub is a harmless no-op unless that specific repo also has a
`.pre-commit-config.yaml` (pre-commit checks for that file when the hook
fires).

The step's `check` reads back `init.templateDir`, so `plan`/`status` are
honest and a second `apply` is a fast no-op (pre-commit's own
`init-templatedir` is itself idempotent, so it's safe to re-run if the
config ever drifts).

## Requirements

- The **`pre-commit`** tool on `PATH` — `brew install pre-commit` or
  `pipx install pre-commit`. Point the step's `needs` at your install step;
  `on-error = "warn"` in `step.toml` means a missing `pre-commit` won't abort
  the rest of your manifest.
- No sudo — everything here is user-scoped (`~/.config/git/template`, global
  git config).

## Adopt

1. Copy `pre-commit-global.sh` into your config's `steps/`.
2. Paste the `[[step]]` from `step.toml`; add
   `needs = ["<your pre-commit install step>"]`.
3. After applying, clone or init a fresh test repo and confirm the hooks
   landed: `ls .git/hooks/` should show pre-commit's stubs.

## Caveats

- **This only affects repos created/cloned AFTER you run it.** Repos you
  already have on disk keep whatever hooks they had; run `pre-commit
  install` once inside each existing repo you want covered (or `pre-commit
  install --install-hooks` to also prefetch the hook environments).
- **Hooks only execute code if the repo opts in** with a
  `.pre-commit-config.yaml` — the global template alone doesn't run
  anything by itself, it just makes the *wiring* automatic.
- If a repo already has its own hooks in `.git/hooks/` (e.g. from a prior
  manual `pre-commit install`, or a different tool), `git init`/`clone`
  won't silently clobber a hook that already exists at that path outside of
  init/clone time — but on a **fresh** clone/init, the template's stubs are
  what lands first, so pre-commit generally wins unless something else runs
  afterward.
- Setting `init.templateDir` globally means **any** git template content you
  put there (not just pre-commit's) is copied into every future repo —
  don't drop unrelated files in `~/.config/git/template` expecting them to
  stay put.

## Security

**Supply-chain note — read before enabling.**

- **No privilege, no network at apply time.** This sets one global git
  config value and writes hook-stub scripts to `~/.config/git/template`.
  Nothing is downloaded and nothing runs as root.
- **The real blast radius is what pre-commit hooks *do* once a repo enables
  them.** A `.pre-commit-config.yaml` can declare hooks that fetch and run
  arbitrary code (linters, formatters, custom scripts) at commit/push time,
  with your user's privileges, in whatever repo you're working in. This
  recipe doesn't add any hook config anywhere — it only makes the wiring
  automatic *if and when* a repo has one — but it does mean you're one step
  closer to auto-running whatever a cloned repo's `.pre-commit-config.yaml`
  says. **Only enable/trust pre-commit configs in repos you trust**, same as
  you would any other repo-provided build/CI script.
- **Reverse it:** `git config --global --unset init.templateDir`, and
  optionally `rm -rf ~/.config/git/template`. Existing repos' `.git/hooks/`
  are unaffected either way — remove hooks per-repo if needed
  (`pre-commit uninstall`).
