#!/usr/bin/env bats

setup() {
    load "${BATS_LIB_PATH}/bats-support/load.bash"
    load "${BATS_LIB_PATH}/bats-assert/load.bash"

    TMP="$BATS_TEST_TMPDIR"
}

@test "no args exits 0" {
    run lefthook-shfmt
    assert_success
}

@test "non-existent file is skipped" {
    run lefthook-shfmt /nonexistent/file.sh
    assert_success
}

@test "non-shell files are skipped" {
    echo 'hello' > "$TMP/readme.md"
    run lefthook-shfmt "$TMP/readme.md"
    assert_success
}

@test "well-formatted script passes" {
    cat > "$TMP/good.sh" <<'SH'
#!/usr/bin/env bash
if true; then
    echo "hello"
fi
SH
    run lefthook-shfmt --check "$TMP/good.sh"
    assert_success
}

@test "badly-formatted script fails" {
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo "wrong indent"
fi
SH
    run lefthook-shfmt --check "$TMP/bad.sh"
    assert_failure
}

@test "--format mode reformats in place" {
    cat > "$TMP/messy.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo "wrong indent"
fi
SH
    run lefthook-shfmt --format "$TMP/messy.sh"
    assert_success
    run lefthook-shfmt --check "$TMP/messy.sh"
    assert_success
}

@test "default mode is check (diff)" {
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo "wrong indent"
fi
SH
    run lefthook-shfmt "$TMP/bad.sh"
    assert_failure
}
