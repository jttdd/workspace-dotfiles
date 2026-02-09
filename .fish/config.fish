# Base16 Shell
if status --is-interactive
    set BASE16_SHELL "$HOME/.config/base16-shell/"
    source "$BASE16_SHELL/profile_helper.fish"
    base16-material # i'd customize this per workspace to help differenciate them
end

set -gx EDITOR nvim

fish_add_path ~/.local/bin

# Start lspmux server if not already running
if not pgrep -f "lspmux server" > /dev/null
    nohup ~/.cargo/bin/lspmux server > ~/.lspmux.log 2>&1 &
    disown
end

# Vi mode
fish_vi_key_bindings

source ~/.aliases/common.fish
source ~/.aliases/ddog.fish
source ~/.aliases/ddog-libstreaming.fish

# source "$HOME/.cargo/env.fish"

# plugins
# https://github.com/IlanCosman/tide
# https://github.com/jethrokuan/z
# https://github.com/PatrickF1/fzf.fish

# Don't exit with CTRL-D (lots of fat fingering from VIM)
bind -M insert \cd true

# fzf

fzf_configure_bindings  --directory=\ct
