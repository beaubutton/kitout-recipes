# git-conditional-identity

Use your personal git identity everywhere, except under `~/work/`, where a
separate work identity applies automatically.

## What it does

Sets a personal identity as the global default, then wires up git's
`includeIf` mechanism to swap in a work identity by directory:

| Key / file | Value | Why |
|---|---|---|
| `user.name` / `user.email` | your personal identity | the global default, used everywhere |
| `~/.gitconfig-work` | `[user] name`/`email` | the work identity, in its own file |
| `includeIf.gitdir:~/work/.path` | `~/.gitconfig-work` | any repo whose path is under `~/work/` includes that file instead |

Git evaluates `includeIf "gitdir:…"` at config-read time by matching the
repo's path against the pattern, and the trailing `/` means "this directory
and everything under it." So a clone at `~/work/acme/api` picks up
`~/.gitconfig-work` and its `user.name`/`user.email` win (later includes
override earlier config), while a clone anywhere else keeps the personal
identity. No script runs per-repo — it's pure git config, evaluated fresh
every time git reads config in that tree.

The step's `check` reads back `includeIf.gitdir:~/work/.path`, so `plan`/
`status` are honest and a second `apply` is a no-op.

## Requirements

- git 2.13+ (when `includeIf`/`gitdir:` was added — any current macOS git
  satisfies this).
- No sudo, no packages.
- **Edit the placeholders** in `git-conditional-identity.sh` before adopting:
  `PERSONAL_NAME`, `PERSONAL_EMAIL`, `WORK_NAME`, `WORK_EMAIL`. If your work
  repos don't live under `~/work/`, change `WORK_DIR` in the script **and**
  the `~/work/` pattern in both the script's `includeIf` key and
  `step.toml`'s `check` — they must match exactly or the check never
  converges.

## Adopt

1. Copy `git-conditional-identity.sh` into your config's `steps/`.
2. Edit the four placeholder values (and `WORK_DIR` if needed).
3. Paste the `[[step]]` from `step.toml`.
4. After applying, `mkdir -p ~/work` if it doesn't exist yet, clone something
   there, and run `git config user.email` inside it to confirm it resolves
   to your work email.

## Caveats

- **Directory-based, not remote-based.** The switch is keyed on *where the
  repo lives on disk*, not which host it's cloned from. A personal repo
  cloned into `~/work/side-project` will pick up the work identity too —
  keep the tree boundary clean.
- `~/.gitconfig-work` is written **only if absent** — if you already have
  one, this recipe won't touch it (or its placeholder values). Edit it by
  hand afterward if you need to change the work identity later.
- This only sets `user.name`/`user.email`. It doesn't touch signing keys,
  SSH config, or credentials — pair it with `commit-signing-ssh`,
  `commit-signing-gpg`, or `ssh-config-github` if you need per-identity
  signing or host routing too.

## Security

None beyond ordinary git config — this recipe only writes plaintext identity
values.

- **What it changes:** `user.name`/`user.email` in `~/.gitconfig`, an
  `includeIf` pointer, and a new `~/.gitconfig-work` file containing a name
  and email in plaintext (git config is never encrypted).
- **Blast radius:** local only. No network calls, no privilege, no secrets —
  just which name/email gets attached to commits you make under `~/work/`.
  Committer identity is not an authentication mechanism; anyone can put any
  name/email in `user.name`/`user.email`, so this is about correct attribution
  in your own history, not access control.
- **Placeholders ship as literal placeholder text** (`Your Name`,
  `you@example.com`) — the check only verifies the `includeIf` wiring
  exists, not that you've edited the emails, so review the script before
  running it.
- **Reverse it:** `git config --global --unset user.name` / `user.email` /
  `includeIf.gitdir:~/work/.path`, and delete `~/.gitconfig-work`.
