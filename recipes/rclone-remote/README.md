# rclone-remote

Scaffold the shell environment [rclone](https://rclone.org) needs to unlock an
encrypted config, plus a couple of ready-to-uncomment sync aliases — **without
writing `rclone.conf` or embedding any token.**

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:rclone-remote >>>` … `# <<< recipes:rclone-remote <<<`)
containing:

```zsh
export RCLONE_CONFIG_PASS="$(security find-generic-password -s rclone-config -w 2>/dev/null)"

# alias backup-push="rclone sync ~/Documents remote:documents --progress"
# alias backup-pull="rclone sync remote:documents ~/Documents --progress"
```

- `RCLONE_CONFIG_PASS` — if you've set a **configuration password** on your
  `rclone.conf` (rclone's own at-rest encryption for the config file, which
  holds remote credentials), rclone reads this env var instead of prompting
  interactively. The default fetches it from the macOS Keychain via
  `security find-generic-password`; if your config isn't password-protected,
  this line evaluates to an empty string and rclone just ignores it.
- Two **commented-out** aliases showing the shape of a sync command against a
  named remote. Uncomment and edit the remote name / local path / direction
  once your remote actually exists.

This recipe **writes nothing to `rclone.conf`**, defines no remote, and embeds
no credential or token — only env plumbing and example aliases in `~/.zshrc`.
No script.

## Requirements

- The `rclone` binary on `PATH`. Point the step's `needs` at your package step
  (e.g. `brew "rclone"`) — this recipe doesn't install it.
- A remote **already configured** via `rclone config` (interactive setup that
  writes `~/.config/rclone/rclone.conf` with the remote's type and
  credentials). This recipe assumes that's done; it has no part in it.
- If (and only if) you password-protected `rclone.conf`, a Keychain entry
  holding that password:
  ```sh
  security add-generic-password -s rclone-config -a "$USER" -w 'your-config-password'
  ```
- A zsh login shell. For bash/fish, translate the `export`/`alias` lines.

## Adopt

1. Paste the `[[step]]` from `step.toml`; add
   `needs = ["<your rclone install step>"]`.
2. If your `rclone.conf` has a configuration password, store it in Keychain
   (see Requirements) — otherwise leave the block as-is; the lookup just
   returns empty and rclone treats the config as unencrypted.
3. Run `rclone config` once (outside kitout) to set up your actual remote if
   you haven't already.
4. Uncomment and edit the alias lines in the block to match your remote name
   and the local paths you want to sync.
5. `kitout apply`, open a new shell, then test with `rclone lsd remote:`
   (list dirs — read-only) before trying a sync alias.

## Caveats

- **Takes effect in new shells**, not the one that ran the apply.
- **The aliases ship commented out.** Until you uncomment them (and fix the
  remote name — `remote:` is a placeholder), this recipe is inert beyond the
  `RCLONE_CONFIG_PASS` lookup.
- **`RCLONE_CONFIG_PASS` is a no-op if your config isn't encrypted.** rclone
  only consults it when `rclone.conf` was saved with a configuration
  password; otherwise the empty export is harmless.
- This recipe runs **no sync** on its own — no cron, no LaunchAgent. The
  aliases are commands *you* run interactively.
- `rclone sync` is **one-directional and deletes** at the destination
  anything not present at the source — read the Security section before
  uncommenting either alias.

## Security

**Env + aliases only. Secrets stay in `rclone.conf` (optionally
Keychain-encrypted) and the Keychain — never in this recipe's block.**

- **No token or remote credential is written by this recipe.** The block
  contains a Keychain *lookup command* for the config password (not the
  password itself) and two alias templates that reference a remote by name
  only — the actual endpoint URL, access key, or OAuth token for that remote
  lives in `~/.config/rclone/rclone.conf`, created by `rclone config`, wholly
  outside this recipe's control.
- **If you encrypt `rclone.conf` with a config password:** rclone encrypts
  the whole config file (all remotes' credentials) with that one password.
  `RCLONE_CONFIG_PASS` retrieves it from Keychain at shell-start so you're
  not prompted — but anything that can read your shell's environment for the
  session can read that password too. Same exposure tradeoff as any
  Keychain-backed env var.
- **No sudo, no network calls made by this step.** It edits one user-owned
  file. Network access to your remote (S3, Drive, a server, etc.) only
  happens later, when *you* run an `rclone` command via the alias or
  directly.
- **`rclone sync` deletes.** `rclone sync SRC DST` makes `DST` match `SRC`
  exactly — including **deleting files at `DST` that don't exist at `SRC`**.
  The example `backup-push`/`backup-pull` aliases point in opposite
  directions; running the wrong one can delete local files or delete remote
  files. Prefer `rclone copy` (never deletes) while you're getting
  comfortable, and always sanity-check with `rclone sync --dry-run` first.
- **Reverse it:** remove the block from `~/.zshrc`. To fully decommission,
  also delete the Keychain entry
  (`security delete-generic-password -s rclone-config`) and remove the
  remote from `rclone.conf` (`rclone config delete remote`) if you're
  retiring it — neither of which this recipe does for you.
