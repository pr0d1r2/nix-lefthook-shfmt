#!/usr/bin/env bash
set -euo pipefail

cd @SRC@
mapfile -t files < <(find . -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
if [ "${#files[@]}" -gt 0 ]; then
  @ACTIONLINT@/bin/actionlint "${files[@]}"
fi
touch "$out"
