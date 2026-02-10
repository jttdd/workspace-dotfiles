#!/usr/bin/env bash

set -exuo pipefail

sudo add-apt-repository -y ppa:neovim-ppa/unstable && sudo apt update

sudo apt install -y neovim \
  htop \
  ripgrep \
  protobuf-compiler libprotobuf-dev zlib1g-dev libssl-dev \
  libevent-dev ncurses-dev ncurses-dev build-essential bison pkg-config # tmux dev dependencies

# Symlink dotfiles to the root within your workspace
DOTFILES_PATH="$HOME/dotfiles"
find $DOTFILES_PATH -type f -path "$DOTFILES_PATH/.*" |
while read df; do
  link=${df/$DOTFILES_PATH/$HOME}
  mkdir -p "$(dirname "$link")"
  ln -sf "$df" "$link"
done


#### protoc
PB_REL="https://github.com/protocolbuffers/protobuf/releases"
curl -LO $PB_REL/download/v30.2/protoc-30.2-linux-x86_64.zip
unzip protoc-30.2-linux-x86_64.zip -d $HOME/.local


#### Neovim
# https://github.com/junegunn/vim-plug
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

mkdir -p ~/.config/nvim
ln -sf ~/.vimrc ~/.config/nvim/init.vim
ln -sf "$DOTFILES_PATH/.vim/ftplugin" ~/.config/nvim/ftplugin

mkdir -p ~/.vim
ln -sf "$DOTFILES_PATH/.vim/ftplugin" ~/.vim/ftplugin

nvim --headless +PlugInstall +qa

#### Tmux
wget https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz
tar xzvf tmux-3.5a.tar.gz
cd tmux-3.5a
./configure
make && sudo make install
cd ..
rm -rf tmux-3.5a.tar.gz tmux-3.5a

#### Mosh 1.4.0 (for OSC52 clipboard support)
# Temporarily use system protoc to avoid version mismatch
mv ~/.local/bin/protoc ~/.local/bin/protoc.backup 2>/dev/null || true
curl -L https://github.com/mobile-shell/mosh/releases/download/mosh-1.4.0/mosh-1.4.0.tar.gz -o mosh-1.4.0.tar.gz
tar xzf mosh-1.4.0.tar.gz
cd mosh-1.4.0
./configure --prefix=/usr/local
make -j$(nproc)
sudo make install
cd ..
rm -rf mosh-1.4.0.tar.gz mosh-1.4.0
mv ~/.local/bin/protoc.backup ~/.local/bin/protoc 2>/dev/null || true

# Start mosh server
mosh-server

#### Fish Shell (already installed)

# https://github.com/sharkdp/fd
curl -L https://github.com/sharkdp/fd/releases/download/v10.2.0/fd_10.2.0_amd64.deb > fd_10.2.0_amd64.deb
sudo dpkg -i fd_10.2.0_amd64.deb
ln -sf $(which fdfind) ~/.local/bin/fd
rm -f fd_10.2.0_amd64.deb

# https://github.com/sharkdp/bat
curl -L https://github.com/sharkdp/bat/releases/download/v0.25.0/bat_0.25.0_amd64.deb > bat_0.25.0_amd64.deb
sudo dpkg -i bat_0.25.0_amd64.deb
rm -f bat_0.25.0_amd64.deb

# https://github.com/junegunn/fzf
curl -L https://github.com/junegunn/fzf/releases/download/v0.61.3/fzf-0.61.3-linux_amd64.tar.gz > fzf-0.61.3-linux_amd64.tar.gz
tar -xvzf fzf-0.61.3-linux_amd64.tar.gz
mv fzf ~/.local/bin/fzf
rm -f fzf-0.61.3-linux_amd64.tar.gz

#### SSH key doesn't seem to be valid at this point and the workspace gitconfig overrides to use SSH. Temporarily override HOME it so we can clone public git repos
#### Base-16
rm -rf ~/.config/base16-shell && HOME=/foo git clone http://github.com/chriskempson/base16-shell.git ~/.config/base16-shell

# change default shell
sudo chsh -s /bin/fish bits

# https://github.com/jorgebucaran/fisher
# https://github.com/PatrickF1/fzf.fish
# https://github.com/jethrokuan/z
fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source &&
	fisher install jorgebucaran/fisher &&
	fisher install PatrickF1/fzf.fish jethrokuan/z"

mkdir -p ~/.config/fish
ln -sf ~/.fish/config.fish ~/.config/fish/config.fish

#### Claude
mkdir -p ~/.claude
ln -sf "$DOTFILES_PATH/.claude/CLAUDE.md" ~/.claude/CLAUDE.md
mkdir -p ~/.codex
ln -sf "$DOTFILES_PATH/.claude/CLAUDE.md" ~/.codex/AGENTS.md

#### Git
git config --global include.path "~/.gitconfig-ext"

#### Rust

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
rustup component add rust-analyzer

# Install lspmux
source "$HOME/.cargo/env"
cargo install lspmux

#### Cleanup DATADOG_ROOT
if [ -n "${DATADOG_ROOT:-}" ]; then
  echo "Cleaning up unused directories in $DATADOG_ROOT"
  rm -rf "$DATADOG_ROOT/corp-hugo" \
         "$DATADOG_ROOT/documentation" \
         "$DATADOG_ROOT/dogweb" \
         "$DATADOG_ROOT/web-ui" \
         "$DATADOG_ROOT/consul-config" \
         "$DATADOG_ROOT/logs-backend"
fi

echo "Success"
