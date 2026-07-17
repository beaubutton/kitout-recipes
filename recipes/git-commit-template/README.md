# git-commit-template

Seed a **Conventional Commits** skeleton as your global git commit message
template, so every `git commit` (with no `-m`) opens with the shape and the
type list already in front of you.

## What it does

Writes `~/.gitmessage`:

```
# <type>(<optional scope>): <subject, imperative, ≤ 72 chars>
#
# <body — the why, not the what; wrap at 72 cols>
#
# <footer — BREAKING CHANGE:, Closes #123, etc.>
#
# type must be one of:
#   feat     — a new feature
#   fix      — a bug fix
#   docs     — documentation only
#   ...
```

and sets it as git's global template:

```
git config --global commit.template ~/.gitmessage
```

Every guidance line starts with `#`, so git strips them from the final
message exactly like it already strips its own default template comments —
run `git commit` with nothing else to say and you get an empty message
(the guidance disappears, same as if there were no template at all); fill
in the blanks and the guidance lines still get stripped on save.

## Requirements

- No packages, no sudo — plain git config and a file under `$HOME`.

## Adopt

1. Copy `git-commit-template.sh` into your config's `steps/`.
2. (Optional) edit the type list / skeleton shape in the script to match
   your own convention before adopting, if Conventional Commits isn't it.
3. Paste the `[[step]]` from `step.toml`.
4. After applying, run `git commit` (no `-m`) in any repo and confirm the
   skeleton shows up in your editor.

## Caveats

- **Idempotent via a marker, not a blind overwrite.** The script only
  (re)writes `~/.gitmessage` if it's absent, or if it already carries this
  recipe's trailing `# kitout:git-commit-template` marker line. If you
  already have a `~/.gitmessage` from somewhere else (unmarked), this recipe
  **leaves it completely alone** and just points `commit.template` at it —
  no data loss, but also no skeleton swap. Remove or rename your existing
  file first if you want this recipe's version.
- **Repo-level `commit.template` wins over the global one** — if a
  repository (or its maintainers) set their own `commit.template` in local
  config, that takes precedence for that repo.
- A commit template is advisory only — `git commit -m "…"` bypasses it
  entirely, and nothing enforces the `type(scope): subject` shape at commit
  time. Pair with a `commit-msg` hook (this cookbook's `pre-commit-global`,
  or a project-specific hook) if you want it enforced, not just suggested.

## Security

None — this is a local editor convenience, not privilege or network access.

- **What it changes:** one file (`~/.gitmessage`) and one git config key
  (`commit.template`), both user-scoped plaintext.
- **Blast radius:** nothing beyond what shows up in your editor when you
  run `git commit`. No code executes, no network calls, no privilege.
- **Reverse it:** `git config --global --unset commit.template`, and
  `rm ~/.gitmessage` if you don't want the file either.
