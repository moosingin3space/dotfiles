#!/usr/bin/env bash
#
# This script installs all dotfiles into their proper place.
# There are _no_ special needs here.

set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
brewfile="${BREWFILE:-"$repo_root/Brewfile"}"

brew bundle check --file "$brewfile" || brew bundle install --file "$brewfile"

mkdir -p $HOME/.config/fish
ln -sf "$repo_root/config.fish" "$HOME/.config/fish/config.fish"

mkdir -p $HOME/.config/mise
ln -sf "$repo_root/mise.toml" "$HOME/.config/mise/config.toml"
if [[ "${DOTFILES_SKIP_MISE:-0}" != "1" ]]; then
  (cd /tmp && mise install)
fi

mkdir -p $HOME/.config/helix/themes
ln -sf "$repo_root/helix.toml" "$HOME/.config/helix/config.toml"
ln -sf "$repo_root/themes/helix-lucario.toml" "$HOME/.config/helix/themes/lucario.toml"

mkdir -p $HOME/.config/jj
ln -sf "$repo_root/jj.toml" "$HOME/.config/jj/config.toml"

mkdir -p $HOME/.config/spotifyd
ln -sf "$repo_root/spotifyd.conf" "$HOME/.config/spotifyd/spotifyd.conf"

mkdir -p $HOME/.config/herdr
ln -sf "$repo_root/herdr.toml" "$HOME/.config/herdr/config.toml"

mkdir -p $HOME/.config/herdr/plugins/config/herdr-lazy
ln -sf "$repo_root/herdr-lazy-plugins.list" "$HOME/.config/herdr/plugins/config/herdr-lazy/plugins.list"

mkdir -p $HOME/.config/yazi
ln -sf "$repo_root/yazi.toml" "$HOME/.config/yazi/yazi.toml"

mkdir -p $HOME/.config/rio/themes
ln -sf "$repo_root/rio.toml" "$HOME/.config/rio/config.toml"
ln -sf "$repo_root/themes/rio-lucario.toml" "$HOME/.config/rio/themes/lucario.toml"

mkdir -p $HOME/.var/app/com.rioterm.Rio/config/rio/themes
ln -sf "$repo_root/rio.toml" "$HOME/.var/app/com.rioterm.Rio/config/rio/config.toml"
ln -sf "$repo_root/themes/rio-lucario.toml" "$HOME/.var/app/com.rioterm.Rio/config/rio/themes/lucario.toml"

if [[ "${DOTFILES_SKIP_SYSTEMD:-0}" != "1" ]]; then
  mkdir -p $HOME/.config/systemd/user
  ln -sf "$repo_root/systemd/user/mise-upgrade.service" "$HOME/.config/systemd/user/mise-upgrade.service"
  ln -sf "$repo_root/systemd/user/mise-upgrade.timer" "$HOME/.config/systemd/user/mise-upgrade.timer"
  ln -sf "$repo_root/systemd/user/dotfiles-pull.service" "$HOME/.config/systemd/user/dotfiles-pull.service"
  ln -sf "$repo_root/systemd/user/dotfiles-pull.timer" "$HOME/.config/systemd/user/dotfiles-pull.timer"
  ln -sf "$repo_root/systemd/user/spotifyd-resume.service" "$HOME/.config/systemd/user/spotifyd-resume.service"
  systemctl --user daemon-reload
  systemctl --user enable --now mise-upgrade.timer
  systemctl --user enable --now dotfiles-pull.timer

  mkdir -p $HOME/.local/bin
  systemctl --user enable spotifyd-resume.service
fi
