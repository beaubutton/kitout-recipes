# direnv-hook

Hook [direnv](https://direnv.net) into zsh so per-directory `.envrc` files load
and unload environment variables automatically as you `cd` in and out.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:direnv >>>` … `# <<< recipes:direnv <<<`) containing:

```zsh
eval "$(direnv hook zsh)"
```

That installs a `precmd` hook: when you enter a directory with an **authorized**
`.envrc`, direnv loads its exports; when you leave, it unloads them. Everything
outside the markers stays yours; kitout only rewrites the block. No script.

## Requirements

- The `direnv` binary on PATH (`brew "direnv"`). Point the step's `needs` at your
  package step.
- A zsh login shell. For bash/fish, change `hook zsh` accordingly.

## Adopt

Paste the `[[step]]` from `step.toml`; add `needs = ["<direnv install step>"]`.
Nothing to copy into `steps/`. Open a new shell, drop an `.envrc` in a project, run
`direnv allow`, and watch the env load.

## Caveats

- **Takes effect in new shells**, not the one that ran the apply.
- **The hook should be the last thing in `~/.zshrc`.** direnv's docs recommend the
  hook line come after everything else (especially prompt tools that also set a
  `precmd`, like Starship). If you manage the rest of `~/.zshrc` with kitout, order
  this step after those, and keep this block near the bottom of the file.
- **`.envrc` files are not trusted until you `direnv allow` them.** direnv refuses
  to load an `.envrc` it hasn't seen approved — including after any edit — and warns
  instead. This is a feature (see Security).

## Security

**Read this — direnv exists to run arbitrary shell code when you enter a directory,
and its whole safety model is the `allow` gate.**

- **`.envrc` is executable shell, not a static key=value file.** When authorized, it
  runs in your shell context on `cd`. A malicious `.envrc` in a repo you clone could
  run anything *you* can — but only **after you explicitly `direnv allow` it**.
- **The allow gate is the protection, and it's on you.** direnv will not source an
  `.envrc` until you run `direnv allow` in that directory, and it **re-blocks on
  every change** (the approval is content-hashed). The failure mode is habitually
  running `direnv allow` without reading the `.envrc` first — treat allowing an
  `.envrc` from an untrusted repo like running its install script.
- **The hook line itself is benign.** `eval "$(direnv hook zsh)"` evals the output
  of the `direnv` binary you installed (its documented setup); it installs the
  precmd hook and does nothing on its own until an authorized `.envrc` exists.
- **No privilege, no network.** The recipe only edits your `~/.zshrc`.
- **Reverse it:** remove the block from `~/.zshrc`. To revoke a specific project,
  `direnv deny` (or `rm` its entry from `~/.local/share/direnv/allow`).
