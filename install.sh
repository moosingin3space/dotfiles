#!/usr/bin/env bash
#
# This script installs all dotfiles into their proper place.
# There are _no_ special needs here.

brew bundle check || brew bundle install

mkdir -p $HOME/.config/fish
ln -sf "$PWD/config.fish" "$HOME/.config/fish/config.fish"

mkdir -p $HOME/.config/mise
ln -sf "$PWD/mise.toml" "$HOME/.config/mise/config.toml"
(cd /tmp && mise install)

mkdir -p $HOME/.config/helix
ln -sf "$PWD/helix.toml" "$HOME/.config/helix/config.toml"

mkdir -p $HOME/.config/jj
ln -sf "$PWD/jj.toml" "$HOME/.config/jj/config.toml"

mkdir -p $HOME/.config/spotifyd
ln -sf "$PWD/spotifyd.conf" "$HOME/.config/spotifyd/spotifyd.conf"

mkdir -p $HOME/.config/systemd/user
ln -sf "$PWD/systemd/user/mise-upgrade.service" "$HOME/.config/systemd/user/mise-upgrade.service"
ln -sf "$PWD/systemd/user/mise-upgrade.timer" "$HOME/.config/systemd/user/mise-upgrade.timer"
systemctl --user daemon-reload
systemctl --user enable --now mise-upgrade.timer
