#!/usr/bin/env bash
set -euo pipefail

cd @SRC@
mapfile -t files < <(find . -type f \( -name '*.yml' -o -name '*.yaml' \) | sort)
if [ "${#files[@]}" -gt 0 ]; then
  @ACTIONLINT@/bin/actionlint "${files[@]}"
fi
# shellcheck disable=SC2154 # out is provided by the Nix runCommand builder.
touch "$out"
