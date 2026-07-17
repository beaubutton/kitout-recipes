# sdkman

Wire [SDKMAN!](https://sdkman.io) — the SDK manager for Java, Kotlin, Gradle,
Maven, Scala, and friends — into zsh.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:sdkman >>>` … `# <<< recipes:sdkman <<<`) containing:

```zsh
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
```

The `[[ -s … ]]` guard means the block is safe to apply **before** SDKMAN is
installed: it sets `SDKMAN_DIR` either way, but only sources the init script if
it actually exists, so an unconverted machine just gets a no-op export instead
of a "no such file" error in every new shell. Everything outside the markers
stays yours; kitout only rewrites the block. No script.

**This recipe does not install SDKMAN.** SDKMAN has no Homebrew formula — its
documented install path is its own installer script (see Requirements). This
recipe only wires the shell init once SDKMAN is on disk.

## Requirements

- SDKMAN installed to `~/.sdkman` via its own installer:
  `curl -s "https://get.sdkman.io" | bash`. There's no Homebrew formula for
  SDKMAN itself; this is the tool's documented (and only officially supported)
  install path. Run it yourself, once, before or after adopting this recipe —
  see Security for what that script does.
- A zsh login shell. For bash, target `~/.bashrc` instead (SDKMAN's installer
  can also add itself there directly).

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest.
2. `kitout apply`.
3. If you haven't already, install SDKMAN itself:
   `curl -s "https://get.sdkman.io" | bash`.
4. Open a new shell, then `sdk version` and `sdk install java`.

Nothing to copy into `steps/` — this recipe is the shell wiring only.

## Caveats

- **Takes effect in new shells**, not the one that ran the apply.
- **Doesn't install SDKMAN.** If `~/.sdkman/bin/sdkman-init.sh` is never
  created, the block silently no-ops forever — that's by design (see What it
  does), not a bug, but it means "adopt this recipe" and "get SDKMAN" are two
  separate steps.
- SDKMAN's own installer **also** offers to edit your rc files for you when you
  run it interactively. If you let it, you may end up with two init blocks
  (its own plus this one) — harmless (the guard makes re-sourcing safe) but
  redundant; feel free to remove SDKMAN's auto-added block and keep just this
  kitout-managed one, or vice versa.

## Security

- **No privilege, no network from this step.** It only edits your own
  `~/.zshrc`. The `source "$SDKMAN_DIR/bin/sdkman-init.sh"` line only runs if
  that file already exists — this step doesn't fetch or execute anything
  itself.
- **The real trust decision is SDKMAN's own installer**, which this recipe
  deliberately does not run for you: `curl -s "https://get.sdkman.io" | bash`
  pipes a remote script straight to a shell, and that script downloads and
  unpacks SDKMAN's candidate archives from SDKMAN's CDN. Read it before you run
  it if you want to know exactly what it does
  (`curl -s "https://get.sdkman.io"` with no `| bash` shows you the script).
- **Once sourced**, `sdkman-init.sh` runs on every new shell and defines the
  `sdk` function/completions; SDK candidates you later `sdk install` are
  downloaded (over HTTPS) from SDKMAN's candidate repositories and run as
  ordinary JVM-ecosystem tools — the normal exposure of a version manager, not
  something this recipe adds.
- **Reverse it:** remove the block from `~/.zshrc`. To remove SDKMAN entirely,
  `rm -rf ~/.sdkman` (SDKMAN's own `sdk uninstall` only removes individual
  candidates, not itself).
