# kitout-recipes

A cookbook of reusable **[kitout](https://github.com/beaubutton/kitout) steps** for
common macOS workstation tasks — the things that don't have a dedicated step type,
so people keep rewriting the same `defaultbrowser`/`duti`/`defaults` snippets from
scratch.

Each recipe is **browse-and-copy**: read it, copy it into your own config, own it.
kitout never downloads or runs anything from here — there's no fetch command, no
remote execution. Every recipe ships with docs, a test, and an honest **Security**
note (these are commands that run on your machine).

> New to kitout? A recipe is a step you paste into your `kitout.toml` — see the
> [manifest reference](https://github.com/beaubutton/kitout/blob/main/docs/manifest.md).

## How to use a recipe

1. Open `recipes/<name>/`.
2. Read its `README.md` — especially **Requirements** and **Security**.
3. If it's a `script` recipe, copy `<name>.sh` into your config's `steps/` dir.
4. Paste the `[[step]]` from `step.toml` into your manifest and adjust the `id`,
   `needs`, and any hardcoded value (e.g. which browser) to taste.
5. `kitout plan` to preview, `kitout apply` to converge.

## Recipes

| Recipe | Does | Step type | Notes |
|---|---|---|---|
| [`git-lfs`](recipes/git-lfs) | Enable Git LFS globally | `script` | needs `git-lfs` |
| [`touchid-sudo`](recipes/touchid-sudo) | Authenticate `sudo` with Touch ID | `script` | sudo; macOS 14+ |
| [`finder-power-user`](recipes/finder-power-user) | A sensible Finder preference set | `defaults` | no script |
| [`debloat-apple-apps`](recipes/debloat-apple-apps) | Remove bundled iLife apps | `absent` | destructive; kitout ≥ 0.4.0 |

_More landing continuously — this is the reviewed starter set that proves the
[format](RECIPE-FORMAT.md). Categories on deck: default-app handlers, curated
`defaults` sets, shell/prompt, git, language runtimes, containers/cloud, SSH/secrets,
networking, and agent-era config._

## Contributing

See [RECIPE-FORMAT.md](RECIPE-FORMAT.md). A recipe needs docs, a `test.bats`, and a
`## Security` section, and must pass `shellcheck` + its test in CI. PRs welcome —
recipes that run on other people's machines get reviewed accordingly.
