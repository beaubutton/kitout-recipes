# Shared bats helpers for recipe tests.
# Compose a recipe folder into a throwaway kitout manifest and echo its path:
# the step.toml becomes kitout.toml, and any <name>.sh is dropped into steps/
# so `path = "steps/<name>.sh"` resolves.
compose_recipe() {
  local recipe_dir="$1" work="$2"
  mkdir -p "$work/steps"
  cp "$recipe_dir/step.toml" "$work/kitout.toml"
  local sh
  for sh in "$recipe_dir"/*.sh; do
    [ -e "$sh" ] || continue
    cp "$sh" "$work/steps/"
    chmod +x "$work/steps/$(basename "$sh")"
  done
  echo "$work/kitout.toml"
}

# Skip the calling test unless RECIPE_APPLY is set (effect tests mutate state).
require_apply() {
  [ -n "${RECIPE_APPLY:-}" ] || skip "set RECIPE_APPLY=1 to run the effect test (mutates state — use a VM)"
}
