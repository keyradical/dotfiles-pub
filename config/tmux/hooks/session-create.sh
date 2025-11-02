#!/usr/bin/env bash

session_name=$(tmux display-message -p '#S')
session_layout=~/.local/share/tmux/layouts/session-$session_name
if [ -f "$session_layout" ]; then
  $session_layout
else
  tmux rename-window home
fi
