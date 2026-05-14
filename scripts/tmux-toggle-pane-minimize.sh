#!/usr/bin/env bash
set -euo pipefail

pane_id="$(tmux display-message -p '#{pane_id}')"
saved_height="$(tmux show-options -p -v -t "$pane_id" @restore_height 2>/dev/null || true)"

if [ -n "$saved_height" ]; then
  tmux resize-pane -t "$pane_id" -y "$saved_height"
  tmux set-option -p -u -t "$pane_id" @restore_height
else
  tmux set-option -p -t "$pane_id" @restore_height "$(tmux display-message -p '#{pane_height}')"
  tmux resize-pane -t "$pane_id" -D 99
fi
