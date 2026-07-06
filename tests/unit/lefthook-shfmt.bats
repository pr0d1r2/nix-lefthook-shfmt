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

@test "honors .editorconfig indent_size=4" {
    mkdir -p "$TMP/proj4"
    cat > "$TMP/proj4/.editorconfig" <<'EC'
root = true
[*]
indent_style = space
indent_size = 4
EC
    cat > "$TMP/proj4/x.sh" <<'SH'
#!/usr/bin/env bash
if true; then
    echo "four spaces"
fi
SH
    run shfmt_cmd --check "$TMP/proj4/x.sh"
    assert_success
}

@test "rejects 2-space under .editorconfig indent_size=4" {
    mkdir -p "$TMP/proj4b"
    cat > "$TMP/proj4b/.editorconfig" <<'EC'
root = true
[*]
indent_style = space
indent_size = 4
EC
    cat > "$TMP/proj4b/x.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo "two spaces"
fi
SH
    run shfmt_cmd --check "$TMP/proj4b/x.sh"
    assert_failure
}

@test "honors .editorconfig indent_size=2" {
    mkdir -p "$TMP/proj2"
    cat > "$TMP/proj2/.editorconfig" <<'EC'
root = true
[*]
indent_style = space
indent_size = 2
EC
    cat > "$TMP/proj2/x.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo "two spaces"
fi
SH
    run shfmt_cmd --check "$TMP/proj2/x.sh"
    assert_success
}

@test "mixed .sh and non-.sh args — well-formatted .sh passes" {
    echo 'hello' > "$TMP/notes.txt"
    echo '{}' > "$TMP/data.json"
    cat > "$TMP/good.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo "hello"
fi
SH
    run shfmt_cmd --check "$TMP/notes.txt" "$TMP/good.sh" "$TMP/data.json"
    assert_success
}

@test "mixed .sh and non-.sh args — badly-formatted .sh fails" {
    echo 'hello' > "$TMP/readme.md"
    cat > "$TMP/bad.sh" <<'SH'
#!/usr/bin/env bash
if true; then
    echo "wrong indent"
fi
SH
    run shfmt_cmd --check "$TMP/readme.md" "$TMP/bad.sh"
    assert_failure
}

@test "--format on already-formatted file is idempotent" {
    cat > "$TMP/clean.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo "hello"
fi
SH
    local before
    before=$(cat "$TMP/clean.sh")
    run shfmt_cmd --format "$TMP/clean.sh"
    assert_success
    local after
    after=$(cat "$TMP/clean.sh")
    [ "$before" = "$after" ]
    run shfmt_cmd --check "$TMP/clean.sh"
    assert_success
}

@test "falls back to 2-space when no .editorconfig governs" {
    cat > "$TMP/loose.sh" <<'SH'
#!/usr/bin/env bash
if true; then
  echo "two spaces"
fi
SH
    run shfmt_cmd --check "$TMP/loose.sh"
    assert_success
}
