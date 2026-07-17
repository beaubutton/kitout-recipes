# restic-scaffold

Scaffold the shell environment [restic](https://restic.net) needs — repository
location and a password *command* — **without ever storing the repo password
in a file.**

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:restic-scaffold >>>` … `# <<< recipes:restic-scaffold <<<`)
that exports two env vars restic reads on every invocation:

```zsh
export RESTIC_REPOSITORY="sftp:user@host:/backups"
export RESTIC_PASSWORD_COMMAND="security find-generic-password -s restic -w"
```

- `RESTIC_REPOSITORY` — where your backup repo lives. The default is an
  **sftp placeholder** — restic also supports `rest:`, `s3:`, `b2:`, a local
  path, and more; swap the scheme and target for your actual backend.
- `RESTIC_PASSWORD_COMMAND` — restic runs this command and uses its stdout as
  the repository password, so the password itself is never written to disk by
  this recipe. The default reads from the macOS login Keychain via
  `security find-generic-password`; swap in `op read op://vault/restic/password`
  if you use 1Password instead.

This step **runs no backups**. It only wires up the environment; you invoke
`restic init` (once) and `restic backup`/`restic snapshots`/etc. yourself. No
script — everything outside the markers in `~/.zshrc` is left alone.

## Requirements

- The `restic` binary on `PATH`. Point the step's `needs` at your package step
  (e.g. `brew "restic"`) — this recipe doesn't install it.
- A Keychain entry (or 1Password item) holding the repo password, created
  *before* you rely on this — e.g.:
  ```sh
  security add-generic-password -s restic -a "$USER" -w 'your-repo-password'
  ```
  Use a strong, generated password — losing it means losing access to every
  snapshot in the repo (restic has no password recovery).
- A zsh login shell. For bash/fish, translate the `export` lines to your
  shell's syntax.
- The repository target itself (an SFTP host, S3/B2 bucket, etc.) reachable
  and, for a *new* repo, initialized once with `restic init`.

## Adopt

1. Paste the `[[step]]` from `step.toml`; add
   `needs = ["<your restic install step>"]`.
2. Edit `RESTIC_REPOSITORY` in the block to your real target.
3. Store the repo password out-of-band (Keychain or 1Password — see
   Requirements), and point `RESTIC_PASSWORD_COMMAND` at whichever you used.
4. `kitout apply`, open a new shell, then **once**: `restic init` (new repo)
   or `restic snapshots` (existing repo, proves the password command works).

## Caveats

- **Takes effect in new shells**, not the one that ran the apply.
- **This recipe never runs `restic backup`.** No cron job, no LaunchAgent —
  scheduling backups is a separate, deliberate step you add yourself (e.g. a
  `launchd` plist or a cron recipe) once you've confirmed `restic snapshots`
  works.
- If you swap `RESTIC_PASSWORD_COMMAND` for something else, it must print
  **only** the password to stdout (no trailing prompt text) — test it
  standalone before relying on it: `eval "$RESTIC_PASSWORD_COMMAND"`.
- `RESTIC_REPOSITORY` here is a placeholder (`sftp:user@host:/backups`) —
  `plan`/`apply` will happily write that literal string if you forget to
  edit it. It's not validated against a real reachable repo.

## Security

**Env-only. The repository password is fetched via a command at use-time and
is never written to `~/.zshrc` or any file this recipe touches.**

- **No plaintext secret in the file.** `RESTIC_PASSWORD_COMMAND` is a shell
  command restic runs to *obtain* the password each time it needs it — the
  password itself lives only in the Keychain (or 1Password), which are
  themselves encrypted-at-rest and access-controlled by macOS/1Password, not
  in this recipe's block. If you ever see a `RESTIC_PASSWORD=` line show up
  in your `~/.zshrc`, that did not come from this recipe — remove it.
- **No sudo, no network calls made by this step.** It edits one user-owned
  file. Network access to the repository (SFTP/S3/etc.) only happens later,
  when *you* run a `restic` command.
- **Blast radius of the env vars themselves:** any process in your shell
  session can read `RESTIC_REPOSITORY` and invoke
  `RESTIC_PASSWORD_COMMAND` (and thus retrieve the plaintext password into
  its own memory) for as long as the shell is open — same exposure as any
  exported credential-adjacent env var. Don't export it in shared or
  multi-tenant shell sessions.
- **The repository itself is restic's job to protect:** restic encrypts all
  data client-side before it leaves your machine, so the backend (SFTP host,
  S3 bucket) never sees plaintext — but that protection is only as strong as
  the repo password. Use a strong, unique one and back it up somewhere
  durable (a password manager), because restic has no "forgot password" flow.
- **Reverse it:** remove the block from `~/.zshrc`. To fully decommission,
  also delete the Keychain entry (`security delete-generic-password -s
  restic`) and, if you're retiring the repo, `restic forget`/delete the
  backend data — neither of which this recipe does for you.
