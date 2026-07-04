# SPEC — nix-lefthook-shfmt

## §D — Description

A Nix flake that packages a lefthook-compatible [shfmt](https://github.com/mvdan/sh) wrapper for enforcing shell script formatting in git hooks. The wrapper filters `.sh` files from its arguments, skips non-shell and missing files gracefully, and runs `shfmt` with standardized flags (`-i 2 -ci`). It supports both diff-check and in-place format modes. Consumers can integrate it as a lefthook remote (pulling `lefthook-remote.yml` directly) or as a flake input added to their devShell. The project targets Nix-based development environments on Linux and macOS (amd64 and arm64) and is designed for teams enforcing consistent shell formatting via pre-commit and pre-push hooks.

## §V — Invariants

1. `lefthook-shfmt.sh` must exit 0 when given zero arguments or only non-`.sh` / non-existent files.
2. `lefthook-shfmt.sh --check` must fail on files not matching `shfmt -i 2 -ci` and succeed on conforming files.
3. `lefthook-shfmt.sh --format` must rewrite files in place so they pass a subsequent `--check`.
4. Default mode (no flag) is diff/check (`-d`), not write.
5. The flake must evaluate and build on all four supported systems: `aarch64-darwin`, `x86_64-darwin`, `x86_64-linux`, `aarch64-linux`.
6. Every lefthook command must have a `timeout` (default `${LEFTHOOK_SHFMT_TIMEOUT:-30}`).
7. Lefthook checks appear in both `pre-commit` and `pre-push`; pre-commit scopes to `{staged_files}`, pre-push to `{push_files}`.
8. `dev.sh` must run `lefthook install` only when `.git/hooks/pre-commit` is absent.
9. CI runs on Linux for all triggers (push, PR, dispatch) and on macOS for push and dispatch only.
10. All shell scripts have 1-to-1 bats unit test coverage under `tests/unit/`.
11. Shell scripts contain no function definitions — logic is split into separate scripts.
12. Shell scripts are invoked with `bash script.sh`, never `./script.sh`.
13. No embedded shell in Nix files — shell code lives in external `.sh` files read via `builtins.readFile`.
14. The `nixpkgs-lock` flake input is auto-updated daily via the `update-pins.yml` workflow.

## §I — Interfaces

### CLI — `lefthook-shfmt`

```
lefthook-shfmt [--check | --format] file1.sh [file2.sh ...]
```

| Argument | Description |
|---|---|
| `--check` | Diff mode (exit non-zero on formatting violations). This is also the default when no flag is given. |
| `--format` | Write mode (reformat files in place). |
| `file ...` | Paths to check. Non-`.sh` and non-existent paths are silently skipped. |

Exit codes: `0` = success or nothing to check; non-zero = formatting violation (check mode) or shfmt error.

### Nix Flake Outputs

| Output | Description |
|---|---|
| `packages.<system>.default` | `writeShellApplication` wrapping `lefthook-shfmt.sh` with `shfmt` in `runtimeInputs`. |
| `devShells.<system>.default` | Full dev shell: linters, bats, lefthook, `dev.sh` shellHook. |
| `devShells.<system>.ci` | CI-only shell: same packages, `BATS_LIB_PATH` env var, no shellHook. |

### Lefthook Remote Config — `lefthook-remote.yml`

Consumed by other repos via lefthook `remotes:` directive. Adds `shfmt` commands to `pre-commit` and `pre-push` using the `lefthook-shfmt` wrapper.

### Environment Variables

| Variable | Default | Description |
|---|---|---|
| `LEFTHOOK_SHFMT_TIMEOUT` | `30` | Timeout in seconds for shfmt commands in lefthook hooks. |
| `BATS_LIB_PATH` | Set by devShell | Path to bats helper libraries (bats-support, bats-assert, bats-file). |

### Config Files

| File | Format | Purpose |
|---|---|---|
| `lefthook.yml` | YAML | Local lefthook hooks + remote check imports. |
| `lefthook-remote.yml` | YAML | Exported lefthook config for consumers. |
| `config/lefthook/file_size_limits.yml` | YAML | Per-extension file size limits for the file-size-check hook. |
| `.yamllint.yml` | YAML | yamllint config (disables line-length, relaxes truthy key check). |
| `.markdownlint.yml` | YAML | markdownlint config (disables MD013 line length). |
| `.editorconfig` | INI | Editor formatting: UTF-8, LF, 2-space indent, trim trailing whitespace. |

## §T — Tasks

| status | id | goal |
|---|---|---|
| `x` | T1 | Add `watch_file` entries to `.envrc` for `flake.nix`, `flake.lock`, `dev.sh`, and `lefthook-shfmt.sh` per direnv skill requirement. |
| `x` | T9 | Add `markdownlint-cli` package to `ciCommon` in `flake.nix` so the tool is available in both devShells. §V.5, §B.3, linter skill step 1. |
| `.` | T10 | Fix markdownlint violations in all tracked `.md` files using `.markdownlint.yml` config (MD013 already disabled). Linter skill step 5. |
| `.` | T11 | Add `markdownlint` commands to `lefthook.yml` for `pre-commit` (`{staged_files}`) and `pre-push` (`{push_files}`) with `glob: "*.md"` and timeout. §V.6, §V.7, §B.3, linter skill steps 2–4. |
| `~` | T2 | ~~Add markdownlint lefthook check~~ — split into T9, T10, T11. |
| `.` | T3 | Standardize `actions/checkout` version — `update-pins.yml` uses `@v4` while `ci.yml` uses `@v6`. |
| `.` | T4 | Add bats test for mixed `.sh` and non-`.sh` arguments passed together (currently only tested separately). |
| `.` | T5 | Add bats test for `--format` on an already-formatted file (idempotency). |
| `.` | T6 | Add bats test for `--check` and `--format` with multiple files in a single invocation. |
| `.` | T7 | Refactor `lefthook-bats-unit` in `flake.nix` to use the `wrap` helper pattern (currently manually defined unlike other wrappers). |
| `.` | T8 | Add `nix/direnv.sh` file referenced by direnv skill but not yet present — centralizes watch-file logic. |

## §B — Bugs / Known Issues

1. **`.envrc` has no `watch_file` entries.** The file contains only `use flake`. Changes to `flake.nix`, `dev.sh`, or `lefthook-shfmt.sh` do not trigger direnv reload, so the dev shell can go stale after edits. The direnv skill requires watching flake modules and dependent files.

2. **`actions/checkout` version mismatch across workflows.** `ci.yml` uses `actions/checkout@v6` while `update-pins.yml` uses `actions/checkout@v4`. Both should use the same version to avoid inconsistent CI behavior.

3. **`.markdownlint.yml` config is unused by lefthook.** The config file exists and markdown files are tracked (`README.md`, `SPEC.md`, skill docs), but no markdownlint command is defined in `lefthook.yml`. This violates the linter skill rule that every tracked file type must have a lefthook linter.

4. **`lefthook-bats-unit` wrapper inconsistency.** All other lefthook wrappers in `flake.nix` use the `wrap` helper function, but `lefthook-bats-unit` is defined inline with a manual `writeShellApplication` call. This makes it harder to maintain consistently if the `wrap` pattern changes.

5. **`ci` devShell sets `BATS_LIB_PATH` differently from `default`.** The `ci` shell sets it as a Nix env attribute (`BATS_LIB_PATH = "..."`), while `default` sets it via `dev.sh` export with placeholder substitution. If the placeholder mechanism changes, the two shells could diverge.

6. **`file-size-check` fails on `.md` files exceeding default limit.** `config/lefthook/file_size_limits.yml` had no `md` extension entry, so markdown files fell under the 4096-byte default. `SPEC.md` (6818 bytes) exceeded this, causing CI failure. Fixed by adding `md: 8192` extension limit.
