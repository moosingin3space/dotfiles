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

mkdir -p $HOME/.config/jjui/themes
ln -sf "$repo_root/jjui.toml" "$HOME/.config/jjui/config.toml"
ln -sf "$repo_root/themes/jjui-lucario.toml" "$HOME/.config/jjui/themes/lucario.toml"

pi_agent_dir="$HOME/.pi/agent"
mkdir -p "$pi_agent_dir/themes"
ln -sf "$repo_root/themes/pi-lucario.json" "$pi_agent_dir/themes/lucario.json"

pi_settings="$pi_agent_dir/settings.json"
if command -v jq >/dev/null 2>&1; then
  pi_settings_tmp="$(mktemp "$pi_agent_dir/settings.json.XXXXXX")"
  if [[ -s "$pi_settings" ]]; then
    jq '.theme = "lucario"' "$pi_settings" > "$pi_settings_tmp"
  else
    jq -n '{theme: "lucario"}' > "$pi_settings_tmp"
  fi
  mv "$pi_settings_tmp" "$pi_settings"
elif command -v node >/dev/null 2>&1; then
  PI_SETTINGS_PATH="$pi_settings" node -e '
    const fs = require("node:fs");
    const path = process.env.PI_SETTINGS_PATH;
    const contents = fs.existsSync(path) ? fs.readFileSync(path, "utf8").trim() : "";
    const settings = contents ? JSON.parse(contents) : {};
    if (!settings || Array.isArray(settings) || typeof settings !== "object") {
      throw new Error("Pi settings must contain a JSON object");
    }
    settings.theme = "lucario";
    fs.writeFileSync(path, `${JSON.stringify(settings, null, 2)}\n`);
  '
fi

mkdir -p $HOME/.config/glow
ln -sf "$repo_root/glow.yml" "$HOME/.config/glow/glow.yml"
ln -sf "$repo_root/themes/glow-lucario.json" "$HOME/.config/glow/lucario.json"

mkdir -p "$HOME/.config/leaf"
ln -sf "$repo_root/leaf.toml" "$HOME/.config/leaf/config.toml"
ln -sf "$repo_root/themes/leaf-lucario.toml" "$HOME/.config/leaf/lucario.toml"

mkdir -p $HOME/.config/spotifyd
ln -sf "$repo_root/spotifyd.conf" "$HOME/.config/spotifyd/spotifyd.conf"

mkdir -p $HOME/.config/herdr
ln -sf "$repo_root/herdr.toml" "$HOME/.config/herdr/config.toml"

mkdir -p $HOME/.config/herdr/plugins/config/herdr-lazy
ln -sf "$repo_root/herdr-lazy-plugins.list" "$HOME/.config/herdr/plugins/config/herdr-lazy/plugins.list"

collie_config_dir="$HOME/.config/herdr/plugins/config/herdr.collie"
collie_env="$collie_config_dir/.env"
mkdir -p "$collie_config_dir"
if [[ ! -e "$collie_env" ]]; then
  printf '%s\n' \
    '# Collie is managed through Herdr; set COLLIE_TRUSTED_USER manually.' \
    'COLLIE_MUX=herdr' \
    > "$collie_env"
fi

mkdir -p $HOME/.config/yazi
ln -sf "$repo_root/yazi.toml" "$HOME/.config/yazi/yazi.toml"
ln -sf "$repo_root/themes/yazi-lucario.toml" "$HOME/.config/yazi/theme.toml"

mkdir -p $HOME/.config/rio/themes
ln -sf "$repo_root/rio.toml" "$HOME/.config/rio/config.toml"
ln -sf "$repo_root/themes/rio-lucario.toml" "$HOME/.config/rio/themes/lucario.toml"

mkdir -p $HOME/.var/app/com.rioterm.Rio/config/rio/themes
ln -sf "$repo_root/rio.toml" "$HOME/.var/app/com.rioterm.Rio/config/rio/config.toml"
ln -sf "$repo_root/themes/rio-lucario.toml" "$HOME/.var/app/com.rioterm.Rio/config/rio/themes/lucario.toml"

if [[ "${DOTFILES_SKIP_SYSTEMD:-0}" != "1" ]]; then
  systemd_user_dir="${XDG_CONFIG_HOME:-"$HOME/.config"}/systemd/user"
  mkdir -p "$systemd_user_dir"
  systemctl --user disable --now spotifyd-resume.service 2>/dev/null || true

  link_systemd_unit() {
    local source="$1"
    local destination="$2"
    if [[ -d "$destination" && ! -L "$destination" ]]; then
      rmdir "$destination" || {
        printf 'Cannot install systemd unit over non-empty directory: %s\n' "$destination" >&2
        return 1
      }
    fi
    ln -sfnT "$source" "$destination"
  }

  link_systemd_unit "$repo_root/systemd/user/mise-upgrade.service" "$systemd_user_dir/mise-upgrade.service"
  link_systemd_unit "$repo_root/systemd/user/mise-upgrade.timer" "$systemd_user_dir/mise-upgrade.timer"
  link_systemd_unit "$repo_root/systemd/user/dotfiles-pull.service" "$systemd_user_dir/dotfiles-pull.service"
  link_systemd_unit "$repo_root/systemd/user/dotfiles-pull.timer" "$systemd_user_dir/dotfiles-pull.timer"
  link_systemd_unit "$repo_root/systemd/user/spotifyd-resume.service" "$systemd_user_dir/spotifyd-resume.service"
  mkdir -p "$HOME/.local/bin"
  ln -sfnT "$repo_root/systemd/user/spotifyd-resume" "$HOME/.local/bin/spotifyd-resume"
  systemctl --user daemon-reload
  systemctl --user enable --now mise-upgrade.timer
  systemctl --user enable --now dotfiles-pull.timer

  systemctl --user enable --now spotifyd-resume.service
fi
