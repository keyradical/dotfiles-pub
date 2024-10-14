#!/usr/bin/env bash

if [ ! -d $HOME/.local/share/tmux/layouts ]; then
  mkdir -p $HOME/.local/share/tmux/layouts
  echo changed created layouts directory
fi

declare -A symlinks=(
  [$HOME/.config/tmux/tmux.conf]=$HOME/.tmux.conf
)

layouts=(
  session-config
  session-infra
  session-main
  session-visor
  window-auto
  window-tall
  window-wide-left
  window-wide-right
)
for layout in ${layouts[@]}; do
  symlinks[$HOME/.config/tmux/layouts/$layout]=$HOME/.local/share/tmux/layouts/$layout
done

for source in ${!symlinks[@]}; do
  dest=${symlinks[${source}]}
  if [ -L $dest ]; then
    target=`readlink $dest`
    if [ "$target" != "$source" ]; then
      rm $dest
      ln -s $source $dest
      echo changed replace incorrect symlink $dest
    fi
  elif [ -f $dest ]; then
    error symlink failed $dest exists but is a regular file
  else
    ln -s $source $dest
    echo changed created symlink $dest
  fi
done
