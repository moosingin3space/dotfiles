#!/usr/bin/env bash
#
# This script installs all dotfiles into their proper place.
# There are _no_ special needs here.

mkdir -p $HOME/.config/fish
ln -sf "$PWD/config.fish" "$HOME/.config/fish/config.fish"

mkdir -p $HOME/.config/mise
ln -sf "$PWD/mise.toml" "$HOME/.config/mise/config.toml"

mkdir -p $HOME/.config/helix
ln -sf "$PWD/helix.toml" "$HOME/.config/helix/config.toml"
