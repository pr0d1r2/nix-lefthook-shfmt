#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR"
    SCRIPT="$BATS_TEST_DIRNAME/../../lefthook-shfmt.sh"
}

shfmt_cmd() {
    bash "$SCRIPT" "$@"
}

@test "no args exits 0" {
    run shfmt_cmd
    assert_success
}

@test "non-existent file is skipped" {
    run shfmt_cmd /nonexistent/file.sh
    assert_success
}

@test "non-shell files are skipped" {
    echo 'hello' > "$TMP/readme.md"
    run shfmt_cmd "$TMP/readme.md"
    assert_success
}

@test "well-formatted script passes" {
    cat > "$TMP/good.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo "hello"
fi
SH
    run shfmt_cmd --check "$TMP/good.sh"
    assert_success
}

@test "badly-formatted script fails" {
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
if true; then
    echo "wrong indent"
fi
SH
    run shfmt_cmd --check "$TMP/bad.sh"
    assert_failure
}

@test "--format mode reformats in place" {
    cat > "$TMP/messy.sh" <<'SH'
#!/usr/bin/env bash
if true; then
    echo "wrong indent"
fi
SH
    run shfmt_cmd --format "$TMP/messy.sh"
    assert_success
    run shfmt_cmd --check "$TMP/messy.sh"
    assert_success
}

@test "default mode is check (diff)" {
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
if true; then
    echo "wrong indent"
fi
SH
    run shfmt_cmd "$TMP/bad.sh"
    assert_failure
}
