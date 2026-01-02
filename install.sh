#!/usr/bin/env bash
#
# This script installs all dotfiles into their proper place.
# There are _no_ special needs here.

ln -sf "$PWD/config.fish" "$HOME/.config/fish/config.fish"
