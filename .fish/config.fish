# SSH agent: stable socket path so tmux/sub-shells reuse the same agent.
# Interactive shells use the stable path maintained by the workspace socket keeper.
# Non-interactive shells must preserve the inherited forwarded-agent socket.
if status --is-interactive
    set -gx SSH_AUTH_SOCK $HOME/.ssh/ssh_auth_sock

# Only start a workspace-local fallback agent outside an SSH session.
    if not set -q SSH_CONNECTION
        ssh-add -l >/dev/null 2>&1
        if test $status -eq 2
            set -l sock (ssh-agent -s | string match -r --groups-only 'SSH_AUTH_SOCK=([^;]+)')
            ln -snf $sock $SSH_AUTH_SOCK
        end

        if test -f $HOME/.ssh/id_github
            set -l fp (ssh-keygen -lf $HOME/.ssh/id_github.pub 2>/dev/null | awk '{print $2}')
            if not ssh-add -l 2>/dev/null | string match -q "*$fp*"
                ssh-add -q $HOME/.ssh/id_github 2>/dev/null
            end
        end
    end
end

# Base16 Shell
if status --is-interactive
    set BASE16_SHELL "$HOME/.config/base16-shell/"
    source "$BASE16_SHELL/profile_helper.fish"
    base16-material # i'd customize this per workspace to help differenciate them
end

set -gx EDITOR nvim
set -g fish_prompt_pwd_dir_length 0

function fish_prompt
    set -l last_status $status
    set -l cwd (prompt_pwd)
    set -l branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)

    set_color blue
    printf '%s' "$cwd"

    if test -n "$branch"
        set_color brblack
        printf ' ['
        set_color bryellow
        printf '%s' "$branch"
        set_color brblack
        printf ']'
    end

    if test $last_status -ne 0
        set_color red
        printf ' [%s]' "$last_status"
    end

    set_color normal
    printf '> '
end

# Start lspmux server if not already running
if not pgrep -f "lspmux server" >/dev/null
    nohup ~/.cargo/bin/lspmux server >~/.lspmux.log 2>&1 &
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

fzf_configure_bindings --history=\cr --directory=\ct

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv fish)"

# Ensure ~/.local/bin is at the front of PATH (after aliases that may modify PATH)
fish_add_path --prepend --move ~/.local/bin

# Pi
fish_add_path --prepend "/home/bits/.npm-global/bin"
