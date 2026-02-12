# Dotfiles

My dotfiles for
* [neovim](https://neovim.io/)
* [fish shell](https://fishshell.com/)
* [tmux](https://github.com/tmux/tmux)
* git

# Setup
After workspace is created, SSH in, open neovim and run:

```
:PlugInstall
```

# Workspace Tunnel (autossh)
To keep a local tunnel to workspace port `10350` running in the background
while still having a usable forwarded SSH agent on the remote side, use:

```bash
AUTOSSH_GATETIME=0 autossh -M 0 -f -A -T \
  -L 10350:localhost:10350 \
  workspace-jefflai-2 'sh -lc "while :; do sleep 3600; done"'
```

Notes:
* `-f` backgrounds the session.
* `-A` enables SSH agent forwarding.
* The remote keepalive loop keeps a session open so forwarded agent access
  remains available. A pure `-N` tunnel does not create a remote session.
