if status is-interactive
    # Commands to run in interactive sessions can go here
end
### bling.fish source start
test -f /usr/share/ublue-os/bling/bling.fish && source /usr/share/ublue-os/bling/bling.fish
### bling.fish source end
### Mise setup
if command -q mise
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
