#!/usr/bin/env bash
# Set the current kubectl context to a named context that ALREADY exists in your
# kubeconfig. This is a local file edit only: `kubectl config use-context` rewrites
# the `current-context` field in ~/.kube/config and never talks to any cluster.
# Idempotent: a no-op when it's already the current context.
#
# Change WANT to the context you want as default; keep it in sync with the step's
# `check` in step.toml.
set -euo pipefail

want="docker-desktop"

current="$(kubectl config current-context 2>/dev/null || true)"
if [ "$current" = "$want" ]; then
  echo "kubectl context already '$want'."
  exit 0
fi

# Refuse to guess: only switch to a context that's actually defined. This avoids
# creating a dangling current-context and keeps the step read-only about clusters.
if ! kubectl config get-contexts -o name 2>/dev/null | grep -Fxq "$want"; then
  echo "Context '$want' is not in your kubeconfig — add it first, e.g. via" >&2
  echo "'aws eks update-kubeconfig', 'gcloud container clusters get-credentials'," >&2
  echo "or 'kubectl config set-context'. Then re-run. (No cluster was contacted.)" >&2
  exit 1
fi

kubectl config use-context "$want"
echo "kubectl context set to '$want'."
