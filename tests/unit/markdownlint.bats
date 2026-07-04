#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    PROJECT_ROOT="$BATS_TEST_DIRNAME/../.."
    MARKDOWNLINT="$PROJECT_ROOT/.markdownlint.yml"
}

@test ".markdownlint.yml exists" {
    [ -f "$MARKDOWNLINT" ]
}

@test "disables MD013 line length" {
    run grep 'MD013: false' "$MARKDOWNLINT"
    assert_success
}
