# jenv

Activate [jenv](https://www.jenv.be) — a lightweight Java version manager — in
your interactive shell.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:jenv >>>` … `# <<< recipes:jenv <<<`) containing:

```zsh
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
```

The `PATH` export makes the `jenv` shim binary itself reachable; `jenv init -`
then puts `~/.jenv/shims` ahead of it on `PATH` and installs jenv's shell
integration, so `java`/`javac`/etc. resolve to whichever JDK jenv has selected
(globally, per-directory via `.java-version`, or per-shell). Everything outside
the markers stays yours; kitout only rewrites the block. No script.

This recipe installs the *shell activation*, not the `jenv` binary or any JDK —
see Requirements.

## Requirements

- The `jenv` binary on `PATH`: `brew "jenv"`. Point the step's `needs` at
  whatever installs it so the block lands after it.
- **At least one JDK already installed** (jenv doesn't install JDKs itself) —
  e.g. `brew install openjdk`, then `jenv add
  /opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home` and `jenv global
  <version>` to pick a default. Kept out of this recipe on purpose — you may
  have several JDKs and a preferred default already.

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Add
`needs = ["<your jenv install step>"]`. Nothing to copy into `steps/`. Open a
new shell, `jenv add <path-to-a-jdk-home>`, `jenv global <version>`, then
`java -version`.

## Caveats

- **zsh only** as written. For bash, target `~/.bashrc` and use
  `eval "$(jenv init -)"` there too (jenv's init output is shell-aware).
- Applies to **new** shells — `source ~/.zshrc` or open a new terminal for the
  session that ran `apply`.
- Ships **no JDK** — with nothing added via `jenv add`, `java` stays whatever
  it was before (or unavailable) until you add one.
- If you also run sdkman/asdf for Java, don't stack their shell hooks — pick
  one to own `PATH` for `java`.

## Security

Low. It edits a marked block in your own `~/.zshrc` — no privilege, no network
at apply time, and it never touches the rest of the file.

The added lines put `~/.jenv/bin` then `~/.jenv/shims` on `PATH` and `eval` the
output of the `jenv` binary you installed on every shell start — so the trust
boundary is that binary (install it from a source you trust; that's the
Requirements step's concern). jenv's shims **intercept** `java`, `javac`, and
friends and dispatch to the JDK you've selected — it selects among JDKs you
already added, it doesn't download or run anything on its own. Reverse by
deleting the block (or removing the recipe and re-applying).
