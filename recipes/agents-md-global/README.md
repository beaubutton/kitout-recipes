# agents-md-global

Seed a **global `AGENTS.md`** — the house rules every coding agent reads before it
touches your machine — in one managed block.

## What it does

Coding agents look for a project `AGENTS.md` (or `CLAUDE.md`) for instructions, and
most also read a **global** one at a well-known path so your baseline preferences
apply everywhere, not per-repo. This recipe uses kitout's `block-in-file` step to
manage a marked region of **`~/.config/AGENTS.md`** (the cross-agent convention;
Claude also reads `~/.claude/CLAUDE.md`).

Only the region between the markers
(`# >>> agents:global >>>` … `# <<< agents:global <<<`) is managed — kitout
rewrites that block on `apply` and leaves everything outside it, so hand-written
notes above or below the block are never disturbed. No script.

The shipped block is a short, opinionated starter set (prefer the smallest change,
read before writing, never run destructive commands unprompted, keep secrets out).
Rewrite the `block` body to your own standards — that is the point.

## Requirements

None. Plain text in your home directory; no packages, no privilege, no network.

## Adopt

1. Paste the `[[step]]` from `step.toml` into your manifest.
2. Rewrite the `block` body to *your* house rules.
3. Point `target` at the file your agent actually reads:
   - cross-agent: `~/.config/AGENTS.md`
   - Claude Code: `~/.claude/CLAUDE.md`
   - Add a second `[[step]]` (different `id`, same `block`) if you want both.
4. `kitout plan` to preview, `kitout apply` to write the block.

Nothing to copy into `steps/` — it's pure declarative `block-in-file`.

## Caveats

- **Guidance, not enforcement.** An `AGENTS.md` is instructions an agent *may*
  follow; it is not a sandbox or a permission boundary. Do not rely on a line here
  to *prevent* a destructive action — use the agent's real allow/deny controls for
  that. This block sets intent, not hard limits.
- **Marker lines look like headings.** `block-in-file`'s comment prefix is `#`, so
  in a Markdown file the begin/end markers render as H1 headings
  (`# >>> agents:global >>>`). Agents read the raw text so this is purely cosmetic;
  if it bothers you when viewing the file rendered, that is the only downside.
- **Per-agent paths differ and change.** `~/.config/AGENTS.md` is the emerging
  cross-agent convention, but each agent decides what it loads and precedence
  (project file usually overrides global). Confirm your agent reads the path you
  target.

## Security

Low blast radius — it writes plain text you author — but be deliberate about the
*content*, because agents act on it.

- **What it changes:** rewrites one marked block in `~/.config/AGENTS.md` (or the
  file you target). User-scoped, no privilege, no network, nothing downloaded, and
  the rest of the file is left byte-for-byte intact.
- **The block is instructions your agents will read and may act on.** Treat it as
  trusted, security-relevant input: a careless or hostile line ("skip
  confirmations", "commit secrets") would steer every agent that reads it. Review
  the body before adopting, and keep it to guidance you actually want followed
  everywhere.
- **It does not grant or restrict any capability.** It changes what agents are
  *told*, never what they are *allowed* to do — permissions live in each agent's
  own settings, not here.
- **Reverse it:** delete the marked block (or remove the step and re-apply). The
  surrounding file content is unaffected.
