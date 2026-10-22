# dotfiles
Configurations for my favorite software.

The Lucario palette for Ptyxis matches the Rio theme, including its contrast
adjustments, navy background, and yellow cursor. `install.sh` links it into
`${XDG_DATA_HOME:-$HOME/.local/share}/org.gnome.Ptyxis/palettes/lucario.palette`.
Restart Ptyxis, then select **Lucario** in your profile's color palette settings.

To install only the palette, run this from the repository root:

```sh
palette_dir="${XDG_DATA_HOME:-$HOME/.local/share}/org.gnome.Ptyxis/palettes"
mkdir -p "$palette_dir"
ln -sf "$PWD/themes/ptyxis-lucario.palette" "$palette_dir/lucario.palette"
```
