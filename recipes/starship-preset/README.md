# starship-preset

Seed `~/.config/starship.toml` with one of [Starship](https://starship.rs)'s
built-in presets — a good-looking prompt config you then own and edit.

## What it does

Runs `starship preset <name> -o ~/.config/starship.toml` to render a built-in
preset into your config path (respecting `$XDG_CONFIG_HOME` if set). The recipe
defaults to `nerd-font-symbols`; set `STARSHIP_PRESET` in the script to any name
from `starship preset --list` (e.g. `pastel-powerline`, `tokyo-night`,
`gruvbox-rainbow`, `plain-text-symbols`, `jetpack`).

**Seed, not converge.** The step's `check` is satisfied as soon as
`starship.toml` *exists*, so this writes the preset **once** on a fresh machine and
never overwrites a config you've since hand-tuned. The script renders to a temp
file and atomically moves it into place, so a failed render can't leave a partial
file behind.

## Requirements

- The `starship` binary on PATH (`brew "starship"`). Point the step's `needs` at
  your package step.
- The prompt hook itself — `eval "$(starship init zsh)"` in your `~/.zshrc` — is
  **out of scope** here; this recipe only writes the config file. Add the init line
  with a `block-in-file` step (same pattern as the `zoxide`/`direnv-hook` recipes).
- Most presets use **Nerd Font** glyphs; install a Nerd Font
  (`brew "font-hack-nerd-font"` etc.) and select it in your terminal, or use the
  `plain-text-symbols` preset.

## Adopt

1. Copy `starship-preset.sh` into your config's `steps/` directory.
2. (Optional) edit `STARSHIP_PRESET` at the top of the script.
3. Paste the `[[step]]` from `step.toml` into your manifest; add
   `needs = ["<starship install step>"]`.
4. Add a separate `block-in-file` step to put `eval "$(starship init zsh)"` in your
   `~/.zshrc` if you haven't already.

## Caveats

- **Seed semantics:** because the check only tests for the file's existence,
  re-running never refreshes the preset. To adopt a *new* preset, delete
  `~/.config/starship.toml` and re-apply, or just run
  `starship preset <name> -o ~/.config/starship.toml` by hand.
- Presets are a starting point — you're expected to edit the result.
- Preset names change between Starship versions; `starship preset --list` is the
  source of truth for your installed version.

## Security

Low blast radius. It writes one user-scoped file (`~/.config/starship.toml`) — no
privilege, no network, no system state. `starship preset` reads templates bundled
in the `starship` binary you already installed (it does not fetch anything). The
prompt config is data that `starship` interprets, not a shell script your shell
sources — but note that a `starship.toml` *can* run commands via
[`custom` modules](https://starship.rs/config/#custom-commands), so if you swap in
a preset from an untrusted source, skim it first. The bundled presets don't. Reverse
by deleting the file (Starship falls back to its built-in default prompt).
