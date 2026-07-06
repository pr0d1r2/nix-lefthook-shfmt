#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    DIRENV_SH="$BATS_TEST_DIRNAME/../../../nix/direnv.sh"
}

@test "nix/direnv.sh exists" {
    [ -f "$DIRENV_SH" ]
}

@test "nix/direnv.sh has shellcheck shell=bash directive" {
    run grep -q "# shellcheck shell=bash" "$DIRENV_SH"
    assert_success
}

@test "nix/direnv.sh watches flake.nix" {
    run grep -q "watch_file flake.nix" "$DIRENV_SH"
    assert_success
}

@test "nix/direnv.sh watches flake.lock" {
    run grep -q "watch_file flake.lock" "$DIRENV_SH"
    assert_success
}

@test "nix/direnv.sh watches dev.sh" {
    run grep -q "watch_file dev.sh" "$DIRENV_SH"
    assert_success
}

@test "nix/direnv.sh watches lefthook-shfmt.sh" {
    run grep -q "watch_file lefthook-shfmt.sh" "$DIRENV_SH"
    assert_success
}
