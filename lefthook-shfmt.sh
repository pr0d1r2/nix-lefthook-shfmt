# shellcheck shell=bash
# Lefthook-compatible shfmt wrapper.
# Usage: lefthook-shfmt [--check|--format] file1.sh [file2.sh ...]
# Non-.sh files are skipped silently.
# Default flags: -i 4 -ci (4-space indent, indent case bodies).
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

exec shfmt $mode -i 4 -ci "${files[@]}"
