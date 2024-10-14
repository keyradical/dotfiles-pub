layout() {
  if [[ "$1" == "" ]]; then
    echo "usage: layout <layout> [name]"
  else
    ~/.local/share/tmux/layouts/$1
    if [[ "$2" != "" ]]; then
      tmux rename-window $2
    fi
  fi
}
