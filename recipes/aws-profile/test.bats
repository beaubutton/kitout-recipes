#!/usr/bin/env bats
load "$BATS_TEST_DIRNAME/../../lib/recipe.bash"

setup() {
  WORK="$(mktemp -d)"
  MANIFEST="$(compose_recipe "$BATS_TEST_DIRNAME" "$WORK")"
}
teardown() { rm -rf "$WORK"; }

@test "aws-profile: step validates" {
  run kitout validate -m "$MANIFEST"
  [ "$status" -eq 0 ]
}

@test "aws-profile: writes the profile block, preserves the rest, is idempotent" {
  require_apply
  # Isolated HOME with a pre-existing [default] so we can prove it's left alone.
  export HOME="$WORK/home"; mkdir -p "$HOME/.aws"
  printf '[default]\nregion = eu-west-1\n' >"$HOME/.aws/config"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  grep -q '>>> recipes:aws-profile' "$HOME/.aws/config"   # managed block present
  grep -q '\[profile dev\]'          "$HOME/.aws/config"  # profile scaffolded
  grep -q 'region = us-east-1'       "$HOME/.aws/config"
  grep -q 'region = eu-west-1'       "$HOME/.aws/config"  # pre-existing default survives

  # No secrets ever land in the file.
  ! grep -qiE 'aws_access_key_id|aws_secret_access_key|session_token' "$HOME/.aws/config"

  # idempotent: nothing pending on a second plan
  run sh -c "kitout plan -m '$MANIFEST' --json | python3 -c 'import sys,json;print(sum(len(s.get(\"changes\",[])) for s in json.load(sys.stdin)[\"steps\"]))'"
  [ "$output" = "0" ]
}

@test "aws-profile: awscli can read the scaffolded profile" {
  require_apply
  command -v aws >/dev/null || skip "awscli not installed on this runner"
  export HOME="$WORK/home"; mkdir -p "$HOME/.aws"

  run kitout apply -y -m "$MANIFEST"
  [ "$status" -eq 0 ]
  # Proves the block is valid INI the AWS CLI accepts (no cluster/account contacted).
  run aws configure get region --profile dev
  [ "$status" -eq 0 ]
  [ "$output" = "us-east-1" ]
}
