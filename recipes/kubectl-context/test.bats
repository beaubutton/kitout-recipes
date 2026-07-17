#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "kubectl-context: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "kubectl-context: switches within an isolated kubeconfig and is idempotent" {
  require_apply
  command -v kubectl >/dev/null || skip "kubectl not installed on this runner"

  # Isolated, cluster-free kubeconfig — set-context/use-context are pure local
  # file edits, so this never contacts a real cluster or touches ~/.kube/config.
  export KUBECONFIG="$WORK/kubeconfig"
  kubectl config set-context other        --cluster= --user= >/dev/null
  kubectl config set-context docker-desktop --cluster= --user= >/dev/null
  kubectl config use-context other >/dev/null   # start off-target → pending

  run bash "$WORK/steps/kubectl-context.sh"
  [ "$status" -eq 0 ]
  [ "$(kubectl config current-context)" = "docker-desktop" ]

  # Idempotent: already on target → no-op, still exit 0.
  run bash "$WORK/steps/kubectl-context.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"already"* ]]
}

@test "kubectl-context: refuses an undefined context (no cluster contact)" {
  require_apply
  command -v kubectl >/dev/null || skip "kubectl not installed on this runner"

  # An empty kubeconfig has no 'docker-desktop' context → the script must fail
  # loudly instead of pointing at a dangling context.
  export KUBECONFIG="$WORK/empty-kubeconfig"
  kubectl config set-context only-this --cluster= --user= >/dev/null

  run bash "$WORK/steps/kubectl-context.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not in your kubeconfig"* ]]
}
