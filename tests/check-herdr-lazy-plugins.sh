#!/usr/bin/env bash

set -euo pipefail

plugins_file="${1:-herdr-lazy-plugins.list}"
status=0

while IFS= read -r repository || [[ -n "$repository" ]]; do
  [[ -z "$repository" || "$repository" == \#* ]] && continue
  if ! gh api --silent "repos/$repository" >/dev/null; then
    echo "$repository: GitHub repository does not exist or is inaccessible" >&2
    status=1
    continue
  fi
  if ! gh api "repos/$repository/topics" --jq '.names[]' | grep -Fxq herdr-plugin; then
    echo "$repository: missing herdr-plugin topic" >&2
    status=1
  fi
done < "$plugins_file"

exit "$status"
