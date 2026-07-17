# shellcheck shell=bash
# Lefthook-compatible shfmt wrapper.
# Usage: lefthook-shfmt [--check|--format] file1.sh [file2.sh ...]
# Non-.sh files are skipped silently.
# Honors .editorconfig when one governs the files (indent_size,
# switch_case_indent, ...). Falls back to -i 2 -ci (2-space indent,
# indent case bodies) when no .editorconfig is found.
# NOTE: sourced by writeShellApplication — no shebang or set needed.

if [ $# -eq 0 ]; then
  exit 0
fi

mode="-d"
if [ "${1:-}" = "--check" ]; then
  shift
elif [ "${1:-}" = "--format" ]; then
  mode="-w"
  shift
fi

files=()
for f in "$@"; do
  [ -f "$f" ] || continue
  case "$f" in
    *.sh) files+=("$f") ;;
  esac
done

if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

# shfmt only reads .editorconfig when no formatting flag is passed, so
# forcing -i/-ci would silently override a consumer's own indent rules.
# Check each file independently: lefthook may pass files from separate
# worktrees or nested projects with different EditorConfig rules.
status=0
for f in "${files[@]}"; do
  probe=$(dirname -- "$f")
  case "$probe" in
    /*) : ;;
    *) probe="$PWD/$probe" ;;
  esac
  governed=0
  while :; do
    if [ -f "$probe/.editorconfig" ]; then
      governed=1
      break
    fi
    [ "$probe" = "/" ] && break
    probe=$(dirname -- "$probe")
  done

  if [ "$governed" -eq 1 ]; then
    shfmt "$mode" "$f" || status=$?
  else
    shfmt "$mode" -i 2 -ci "$f" || status=$?
  fi
done
exit "$status"
