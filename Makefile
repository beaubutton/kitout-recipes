# kitout-recipes — lint every script, validate + test every recipe.
#   make check          shellcheck + validate every recipe (safe, no machine changes)
#   RECIPE_APPLY=1 make test   also run the effect/idempotency tests (mutates state — use a VM)
.PHONY: check shellcheck test

check: shellcheck test

shellcheck:
	@scripts=$$(find recipes -name '*.sh'); \
	 [ -z "$$scripts" ] || shellcheck $$scripts

test:
	@bats -r recipes
