#!/usr/bin/env bats

setup() {
  load "${BATS_LIB_PATH}/bats-support/load.bash"
  load "${BATS_LIB_PATH}/bats-assert/load.bash"

  PROJECT_ROOT="$BATS_TEST_DIRNAME/../.."
  WORKFLOW="$PROJECT_ROOT/.github/workflows/update-pins.yml"
  CI_WORKFLOW="$PROJECT_ROOT/.github/workflows/ci.yml"
}

@test "update-pins.yml exists" {
  [ -f "$WORKFLOW" ]
}

@test "uses actions/checkout@v6" {
  run grep -q "actions/checkout@v6" "$WORKFLOW"
  assert_success
}

@test "does not use actions/checkout@v4" {
  run grep -q "actions/checkout@v4" "$WORKFLOW"
  assert_failure
}

@test "checkout version matches ci.yml" {
  run bash -c "grep 'actions/checkout@' '$WORKFLOW' | head -1 | sed 's/.*@//' | tr -d '[:space:]'"
  ci_version=$(grep 'actions/checkout@' "$CI_WORKFLOW" | head -1 | sed 's/.*@//' | tr -d '[:space:]')
  assert_output "$ci_version"
}

@test "runs on daily schedule" {
  run grep -q "cron:" "$WORKFLOW"
  assert_success
}

@test "supports workflow_dispatch" {
  run grep -q "workflow_dispatch" "$WORKFLOW"
  assert_success
}

@test "updates nixpkgs-lock flake input" {
  run grep -q "nixpkgs-lock" "$WORKFLOW"
  assert_success
}

@test "runs on ubuntu-latest" {
  run grep -q "ubuntu-latest" "$WORKFLOW"
  assert_success
}
