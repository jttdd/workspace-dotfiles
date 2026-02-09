# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Repository Purpose

Personal dotfiles for configuring neovim, fish shell, tmux, and git across development environments.

# Key Scripts

- `./install.sh` - Initial setup script that installs dependencies (neovim, tmux, fish, ripgrep, fd, bat, fzf, rust) and symlinks dotfiles from this repo to `$HOME`
- `./sync-home.sh` - Copies modified dotfiles from `$HOME` back to this repo for version control (fish aliases, git aliases, CLAUDE.md)

# Architecture

## Dotfiles Organization
- Root level: Core config files (`.vimrc`, `.tmux.conf`, `.gitconfig-ext`)
- `.fish/config.fish`: Fish shell configuration with vi mode, base16 theme, and plugin setup
- `.aliases/`: Fish shell aliases (sourced by config.fish)
  - `common.fish`: Common shell aliases
  - `ddog.fish`: Datadog-specific aliases
  - `ddog-libstreaming.fish`: Datadog libstreaming project aliases
- `aliases/`: Synced copies of `.aliases/` files (tracked in git)

## Workflow
Files are symlinked from this repo to `$HOME` during installation. When modifying dotfiles in `$HOME`, run `sync-home.sh` to copy changes back to this repo.

# Neovim Setup
- Uses vim-plug as plugin manager
- After installation, run `:PlugInstall` in neovim
- Config is symlinked: `~/.vimrc` → `~/.config/nvim/init.vim`

# Git Configuration
- `.gitconfig-ext` contains git aliases and settings
- Included in global git config via: `git config --global include.path "~/.gitconfig-ext"`
- Git aliases use branch naming convention: `jeff.lai/<branch-name>`

# Fish Shell
- Uses fisher plugin manager
- Plugins: fzf.fish, z (directory jumper)
- Vi mode enabled
- Sources three alias files from `~/.aliases/`
- Adds `~/.local/bin` to PATH

# Tools Installed
- `rg` (ripgrep): Fast grep alternative
- `fd`: Fast find alternative
- `bat`: Cat with syntax highlighting
- `fzf`: Fuzzy finder
- `mosh`: Mobile shell
