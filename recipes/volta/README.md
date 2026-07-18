# volta

Wire [Volta](https://volta.sh) — a JavaScript tool manager that **pins** Node,
npm, pnpm, and Yarn versions per-project — into zsh.

## What it does

Uses kitout's `block-in-file` step to manage a marked region of `~/.zshrc`
(`# >>> recipes:volta >>>` … `# <<< recipes:volta <<<`) containing:

```zsh
export VOLTA_HOME="$HOME/.volta"
case ":$PATH:" in
  *":$VOLTA_HOME/bin:"*) ;;
  *) export PATH="$VOLTA_HOME/bin:$PATH" ;;
esac
```

`VOLTA_HOME` tells Volta where its shims and installed tool versions live;
putting `$VOLTA_HOME/bin` on `PATH` makes those shims resolve ahead of any
system Node/npm. The `case` guard checks whether that directory is already a
`PATH` segment before prepending it, so sourcing this block repeatedly never
stacks up duplicate entries. Everything outside the markers stays yours;
kitout only rewrites the block. No script.

Once active, Volta's shims read a project's `package.json`
(`"volta": {"node": "20.11.0", ...}`) and transparently run the pinned
version — no `nvm use`/`fnm use` step required per-directory.

## Requirements

- The `volta` binary on `PATH`: `brew install volta`. Point the step's `needs`
  at whatever installs it.
- A zsh login shell. For bash, target `~/.bashrc` instead (same lines work).

## Adopt

Paste the `[[step]]` from `step.toml` into your manifest. Add
`needs = ["<your volta install step>"]`. Nothing to copy into `steps/`. Open a
new shell, then `volta install node` (sets a default) and, inside a project,
`volta pin node@20`.

## Caveats

- Applies to **new** shells — `source ~/.zshrc` or open a new terminal for the
  session that ran `apply`.
- Ships **no Node/npm version** — `volta install`/`volta pin` are on you.
- If you also run fnm/nvm/asdf for Node, don't stack their shell hooks with
  Volta — pick one to own `PATH` for `node`/`npm`.
- Volta's pin lives in `package.json`, committed to the repo — anyone who
  clones the project and has Volta installed gets the same tool versions
  automatically; that's the point, but it means the pin is repo-visible, not
  private.

## Security

Low. It edits a marked block in your own `~/.zshrc` — no privilege, no network
at apply time, and it never touches the rest of the file.

The added lines only set `VOLTA_HOME` and extend `PATH`; there's no `eval` of
command output, so no dynamic code runs at shell startup beyond the export
itself. Volta's shims **intercept** `node`, `npm`, `pnpm`, `yarn`, and dispatch
to the version pinned by the current project's `package.json` (or your
configured default) — on first use of a pinned version it doesn't hold
locally, Volta downloads that Node/npm/etc. release over HTTPS from the official
distribution, the normal exposure of any version manager. A malicious
`package.json` could only pin a version string, not arbitrary code — but
running that project's `npm install` afterward carries npm's usual
lifecycle-script exposure, same as without Volta. Reverse by deleting the
block (or removing the recipe and re-applying).
