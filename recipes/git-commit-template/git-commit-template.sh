#!/usr/bin/env bash
# Write a Conventional-Commits skeleton to ~/.gitmessage and set it as git's
# global commit template (commit.template). Every guidance line in the
# skeleton starts with "#", so git strips them from the final message same
# as it already strips its own default comments — an empty `git commit`
# just opens an editor with the skeleton to fill in; leaving it untouched
# results in an empty commit message same as without a template.
#
# Idempotent: the file is (re)written only if it's absent OR already marked
# as managed by this recipe (a trailing "kitout:git-commit-template"
# comment) — content is static, so rewriting a converged managed file is a
# no-op. A file that exists but ISN'T marked (hand-written by the user, or
# from another tool) is left completely alone. The git config is set only
# if it doesn't already point at ~/.gitmessage.
set -euo pipefail

TEMPLATE_PATH="$HOME/.gitmessage"
MARKER="# kitout:git-commit-template"

write_template() {
  cat >"$TEMPLATE_PATH" <<EOF
# <type>(<optional scope>): <subject, imperative, ≤ 72 chars>
#
# <body — the why, not the what; wrap at 72 cols>
#
# <footer — BREAKING CHANGE:, Closes #123, etc.>
#
# type must be one of:
#   feat     — a new feature
#   fix      — a bug fix
#   docs     — documentation only
#   style    — formatting, no code change
#   refactor — neither fixes a bug nor adds a feature
#   perf     — a performance improvement
#   test     — adding or correcting tests
#   build    — build system or external dependencies
#   ci       — CI configuration
#   chore    — everything else (tooling, deps, etc.)
#
# Lines starting with '#' are stripped from the final commit message.
$MARKER
EOF
}

if [ ! -f "$TEMPLATE_PATH" ]; then
  write_template
  echo "  wrote $TEMPLATE_PATH"
elif grep -qxF "$MARKER" "$TEMPLATE_PATH"; then
  write_template
  echo "  refreshed $TEMPLATE_PATH (already managed by this recipe)"
else
  echo "  $TEMPLATE_PATH exists and isn't managed by this recipe — left untouched"
fi

if [ "$(git config --global --get commit.template 2>/dev/null)" = "$TEMPLATE_PATH" ]; then
  echo "Commit template already configured."
  exit 0
fi

git config --global commit.template "$TEMPLATE_PATH"
echo "  set commit.template = $TEMPLATE_PATH"
echo "Commit message template configured."
