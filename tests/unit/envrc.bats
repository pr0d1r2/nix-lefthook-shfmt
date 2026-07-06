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

@test ".envrc watches nix/direnv.sh" {
    run grep -q "watch_file nix/direnv.sh" "$ENVRC"
    assert_success
}

@test ".envrc sources nix/direnv.sh" {
    run grep -q "\. nix/direnv.sh" "$ENVRC"
    assert_success
}
