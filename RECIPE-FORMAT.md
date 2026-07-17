# Recipe format

A **recipe** is a reusable [kitout](https://github.com/beaubutton/kitout) step you
can copy into your own config, plus the docs and a test that make it safe to
trust. Recipes are **browse-and-copy** — nothing here is downloaded or executed
by kitout automatically. You read it, you copy it, you own it.

## Folder layout

```
recipes/<name>/
├── README.md      # required — what it does, requirements, how to adopt, caveats, SECURITY
├── step.toml      # required — the [[step]] snippet to paste into your manifest
├── <name>.sh      # required *iff* it's a `script` recipe; omit for defaults/absent/merge/block recipes
└── test.bats      # required — proves the check + idempotency (and, when safe, the effect)
```

`<name>` is kebab-case and unique.

## `step.toml`

The exact `[[step]]` block to paste, self-contained and copy-ready:

- Fill in `check`, and `on-error = "warn"` when the step is GUI-gated or optional.
- Any hard dependency (a tool that must be installed first) goes in a **comment**,
  not a hard `needs` — a recipe can't know your step ids. Example:
  `# needs: add needs = ["<your package step>"] if the tool isn't already present`.
- For `script` recipes, `path = "steps/<name>.sh"` — i.e. where the user drops the
  script in *their* repo.

## `<name>.sh` (script recipes)

- `#!/usr/bin/env bash`, `set -euo pipefail`.
- **Idempotent**: exit 0 fast when already converged (mirror the step's `check`).
- Plain `echo` output; kitout owns the presentation.
- `sudo` inline where privilege is needed — the recipe README must say so.
- Must pass `shellcheck` (CI enforces it).

## `README.md`

Required sections, in order:

1. **Title + one-liner** — what it does in a sentence.
2. **What it does** — the mechanism (which command / defaults key / API), and any
   platform notes (macOS version floors, Apple-Silicon-only, etc.).
3. **Requirements** — brew formulae/casks or tools that must exist first.
4. **Adopt** — the literal copy steps (drop the `.sh` in `steps/`, paste `step.toml`).
5. **Caveats** — GUI prompts, non-idempotent edges, what it *won't* do.
6. **Security** — **required, never omit.** State the blast radius honestly. If the
   answer is "none, it's a UI preference," say exactly that. If it touches auth,
   system files, the network, or removes data, spell out what and how to reverse it.

## `test.bats`

Every recipe is tested. A test must, at minimum:

1. Compose `step.toml` into a temp manifest and assert **`kitout validate`** passes
   (the step parses and builds). Always safe, always run in CI.
2. Assert the **`check` logic**: pending in a clean state, satisfied after the effect.
3. When the effect is **safe on an ephemeral runner** (git config, a dummy app, a
   `defaults` key), `apply` and assert the effect **and idempotency** (a second
   `plan` shows nothing pending).

Gate anything **destructive, GUI-gated, or irreversible** behind `RECIPE_APPLY=1`
so CI validates it without running it, and test destructive recipes against a
**dummy fixture** (e.g. a throwaway `/Applications/…test.app`), never a real target.

## CI

`.github/workflows/ci.yml` runs on a macOS runner: `shellcheck` every script,
then every `test.bats`. A recipe doesn't merge red.
