if status is-interactive
    # Commands to run in interactive sessions can go here
end

### Desktop session environment
# Herdr keeps its server (and therefore its PTY children) alive after the
# terminal that started it exits.  Recover the local desktop endpoints when a
# shell was started without the session environment, such as after a server
# restart from a launcher or a headless context.
if not set -q XDG_RUNTIME_DIR
    set -l runtime_dir "/run/user/"(id -u)
    if test -d "$runtime_dir"
        set -gx XDG_RUNTIME_DIR "$runtime_dir"
    end
end

if set -q XDG_RUNTIME_DIR
    if not set -q WAYLAND_DISPLAY
        for wayland_socket in "$XDG_RUNTIME_DIR"/wayland-*
            if test -S "$wayland_socket"
                set -gx WAYLAND_DISPLAY (string replace -r '^.*/' '' -- "$wayland_socket")
                break
            end
        end
    end

    if not set -q DBUS_SESSION_BUS_ADDRESS
        if test -S "$XDG_RUNTIME_DIR/bus"
            set -gx DBUS_SESSION_BUS_ADDRESS "unix:path=$XDG_RUNTIME_DIR/bus"
        end
    end
end

eval "$(brew shellenv)"
### bling.fish source start
test -f /usr/share/ublue-os/bling/bling.fish && source /usr/share/ublue-os/bling/bling.fish
### bling.fish source end
### Mise setup
if [ "$(command -v mise)" ]
    if status is-interactive
        mise activate fish | source
    else
        mise activate fish --shims | source
    end
end
### Mise setup end

### Amp
test -f $HOME/.amp/bin/amp && fish_add_path $HOME/.amp/bin
###

# Added by Antigravity CLI installer
set -gx PATH "/var/home/moosnat/.local/bin" $PATH

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# Yazi
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
        builtin cd -- "$cwd"
    end
    command rm -f -- "$tmp"
end
