if ! tmux list-sessions -F '#{session_name}' | grep 'visor' > /dev/null; then
  tmux new-session -d -s visor
  tmux rename-window -t visor:0 home
fi
tmux attach-session -t visor
exit
