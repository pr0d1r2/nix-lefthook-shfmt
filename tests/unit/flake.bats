#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    FLAKE="$BATS_TEST_DIRNAME/../../flake.nix"
}

@test "ciCommon includes markdownlint-cli" {
    run grep -q "pkgs.markdownlint-cli" "$FLAKE"
    assert_success
}
