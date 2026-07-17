# claude-statusline

Seed a **Claude Code status line** — model, context-window usage, and current
directory in the bar at the bottom — into `~/.claude/settings.json`.

## What it does

Claude Code runs any shell command you set as `statusLine` and shows its stdout in
a persistent bar, feeding it session JSON on stdin. This recipe uses kitout's
`json-merge` step (`mode = "seed"`) to add a `statusLine` key to
`~/.claude/settings.json` whose command is a **self-contained `jq` one-liner** —
no separate script to install:

```
[Opus] 8% ctx · kitout
```

It reads `.model.display_name`, `.context_window.used_percentage`, and
`.workspace.current_dir` from the piped JSON and prints
`[Model] NN% ctx · <dirname>`.

**`mode = "seed"` means write-if-absent**: kitout adds the key only when
`settings.json` has no `statusLine`, so it never overwrites one you've already
customized (that is also what makes it idempotent — once present, nothing pends).

## Requirements

- **`jq`** on `PATH` (`brew "jq"`). The status line command is `jq`; without it the
  bar shows nothing. Point the step's `needs` at your jq package step.
- Claude Code (it reads `~/.claude/settings.json`).

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest.
2. Add `needs = ["<your jq step id>"]` if jq isn't already installed earlier.
3. `kitout apply`, then start (or reload) Claude Code to see the bar.
4. Tweak the `jq` string to show whatever the session JSON exposes — cost
   (`.cost.total_cost_usd`), git branch via `.workspace.repo`, rate limits, etc.

Nothing to copy into `steps/` — the command is inline; it's pure `json-merge`.

## Caveats

- **Seed, not converge.** If you later hand-edit `statusLine`, this step stays a
  no-op and won't reset it. To force the recipe's value back, delete your
  `statusLine` key (or switch the step to `mode = "converge"`, which will overwrite
  yours on every apply).
- **The command runs on every render** as a subprocess. A `jq` one-liner is
  negligible; if you swap in a heavy script, the bar can lag.
- **Field names track Claude Code's schema.** The stdin JSON keys are stable but
  vendor-defined. Every field is read with a fallback (`// "?"` for the model,
  `// 0` for the percentage, `// ""` for the directory), so if a future version
  renames or omits one, only the affected part of the line degrades — the command
  still exits 0 and the rest of the bar renders. `used_percentage` and
  `current_dir` are also documented as possibly `null` early in a session or right
  after `/compact`; the fallbacks cover that too.

## Security

- **What it changes:** merges one `statusLine` key into `~/.claude/settings.json`,
  user-scoped. No privilege, no network, nothing downloaded, and any other keys in
  that file are left intact.
- **The value is a command Claude Code will execute every render.** That is the
  feature, and it is the thing to be deliberate about: whatever you put in
  `command` runs as you, in your shell, repeatedly. The shipped value is a single
  read-only `jq` filter that only reads the JSON on stdin and prints a string — it
  touches no files, spawns nothing else, and makes no network calls. **If you edit
  the command, remember you are editing a shell command that auto-runs**; keep it to
  trusted, read-only logic and never interpolate untrusted data into it.
- **No secrets exposed.** The default line prints model name, a context percentage,
  and the current directory's basename — nothing sensitive. If you extend it to
  show cost or paths, that text becomes visible on your screen/shared sessions;
  choose accordingly.
- **Reverse it:** remove the `statusLine` key from `~/.claude/settings.json` (or
  drop the step and delete the key).
