#!/usr/bin/env bash

set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

HOME="$test_home" \
  BREWFILE="$repo_root/tests/Brewfile" \
  DOTFILES_SKIP_SYSTEMD=1 \
  bash "$repo_root/install.sh"

test "$(readlink "$test_home/.config/fish/config.fish")" = "$repo_root/config.fish"
test "$(readlink "$test_home/.config/helix/themes/lucario.toml")" = "$repo_root/themes/helix-lucario.toml"
test "$(readlink "$test_home/.config/herdr/plugins/config/herdr-lazy/plugins.list")" = "$repo_root/herdr-lazy-plugins.list"
test "$(readlink "$test_home/.var/app/com.rioterm.Rio/config/rio/config.toml")" = "$repo_root/rio.toml"
collie_env="$test_home/.config/herdr/plugins/config/herdr.collie/.env"
test -f "$collie_env"
grep -Fx 'COLLIE_MUX=herdr' "$collie_env" >/dev/null
! grep -q '^COLLIE_TRUSTED_USER=' "$collie_env"

# A rerun must preserve the manually maintained access-control setting.
printf '%s\n' 'COLLIE_TRUSTED_USER=owner@example.com' >> "$collie_env"
HOME="$test_home" \
  BREWFILE="$repo_root/tests/Brewfile" \
  DOTFILES_SKIP_SYSTEMD=1 \
  bash "$repo_root/install.sh"
grep -Fx 'COLLIE_TRUSTED_USER=owner@example.com' "$collie_env" >/dev/null

# `mise install` reads the config symlinked by install.sh. Derive the complete
# expected tool list from the same TOML file rather than duplicating it here.
while IFS= read -r tool; do
  HOME="$test_home" mise where "$tool" >/dev/null
done < <(yq -p=toml -o=json -r '.tools | keys[]' "$repo_root/mise.toml")
