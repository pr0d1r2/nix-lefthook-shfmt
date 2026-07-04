#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    ENVRC="$BATS_TEST_DIRNAME/../../.envrc"
}

@test ".envrc contains use flake" {
    run grep -q "use flake" "$ENVRC"
    assert_success
}

@test ".envrc watches flake.nix" {
    run grep -q "watch_file flake.nix" "$ENVRC"
    assert_success
}

@test ".envrc watches flake.lock" {
    run grep -q "watch_file flake.lock" "$ENVRC"
    assert_success
}

@test ".envrc watches dev.sh" {
    run grep -q "watch_file dev.sh" "$ENVRC"
    assert_success
}

@test ".envrc watches lefthook-shfmt.sh" {
    run grep -q "watch_file lefthook-shfmt.sh" "$ENVRC"
    assert_success
}
