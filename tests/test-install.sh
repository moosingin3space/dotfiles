#!/usr/bin/env bash

set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT

HOME="$test_home" \
  BREWFILE="$repo_root/tests/Brewfile" \
  DOTFILES_SKIP_MISE=1 \
  DOTFILES_SKIP_SYSTEMD=1 \
  bash "$repo_root/install.sh"

test "$(readlink "$test_home/.config/fish/config.fish")" = "$repo_root/config.fish"
test "$(readlink "$test_home/.config/helix/themes/lucario.toml")" = "$repo_root/themes/helix-lucario.toml"
test "$(readlink "$test_home/.config/herdr/plugins/config/herdr-lazy/plugins.list")" = "$repo_root/herdr-lazy-plugins.list"
test "$(readlink "$test_home/.var/app/com.rioterm.Rio/config/rio/config.toml")" = "$repo_root/rio.toml"
