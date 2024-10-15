session() {
  if [[ "$1" == "" ]]; then
    echo "usage: session <name> [<host>]"
  else
    local name=$1
    local host=$2
    if [[ "$3" != "" ]]; then
      echo "$fg[red]error:$reset_color invalid argument: $3"
      return 1
    fi
    declare -A hosts
    if [ -f ~/.config/session ]; then
      source ~/.config/session
    fi
    local url=$hosts[$host]
    host=${url:-$host}
    if [[ "$TMUX" == "" ]]; then
      local cmd="tmux new-session -As $name"
      if [[ "$host" != "" ]]; then
        cmd="ssh $host -t $cmd"
      fi
      eval $cmd
    else
      if [[ "$host" != "" ]]; then
        echo "$fg[red]error:$reset_color <host> not allowed inside tmux session"
        return 1
      fi
      tmux list-sessions | grep "$name:" &> /dev/null || \
        tmux new-session -Ads $name -c $HOME
      tmux switch-client -t $name
    fi
  fi
}
