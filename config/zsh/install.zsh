#!/usr/bin/env zsh

error() {
  echo "error: $*"
  exit 1
}

directories=(
  ~/.cache/zsh
  ~/.local/bin
  ~/.local/share/zsh/plugins
  ~/.local/share/zsh/site-functions
)

for directory in $directories; do
  mkdir -p $directory
done

plugins=(
  zsh-users/zsh-autosuggestions
  zsh-users/zsh-history-substring-search
  zsh-users/zsh-syntax-highlighting
  zsh-users/zsh-completions
)

for plugin in $plugins; do
  plugin_name=${plugin/*\//}
  plugin_directory=~/.local/share/zsh/plugins/$plugin_name
  if [ -d $plugin_directory ]; then
    if ! git -C $plugin_directory diff-index --quiet HEAD --; then
      error $plugin_directory contains unstaged changes
    fi
    pull=`git -C $plugin_directory pull`
    if [ "$pull" != "Already up to date." ] && \
       [ "$pull" != "Already up-to-date." ]; then
      echo changed pulled $plugin_directory
    fi
  else
    git clone https://github.com/$plugin.git $plugin_directory > /dev/null
    echo changed cloned $plugin_directory
  fi
  old_plugin_directory=~/.config/zsh/$plugin_name
  if [ -d $old_plugin_directory ]; then
    rm -rf $old_plugin_directory
    echo changed removed $old_plugin_directory
  fi
done

declare -A symlinks
symlinks=(
  ~/.config/zsh/zlogin ~/.zlogin
  ~/.config/zsh/zlogout ~/.zlogout
  ~/.config/zsh/zprofile ~/.zprofile
  ~/.config/zsh/zshenv ~/.zshenv
  ~/.config/zsh/zshrc ~/.zshrc
  ~/.config/zsh/prompt_fresh_setup
  ~/.local/share/zsh/site-functions/prompt_fresh_setup
  ~/.config/zsh/cmake-uninstall ~/.local/bin/cmake-uninstall
  ~/.config/zsh/$ ~/.local/bin/$
  ~/.config/zsh/url/url ~/.local/bin/url
)

for completion in ~/.config/zsh/**/_*; do
  filename=`basename $completion`
  symlinks[$completion]=~/.local/share/zsh/site-functions/$filename
done

completions=( ~/.local/share/zsh/plugins/zsh-completions/src/* )
for completion in $completions; do
  filename=`basename $completion`
  name=${filename:1}
  if command -v $name > /dev/null; then
    symlinks[$completion]=~/.local/share/zsh/site-functions/$filename
  fi
done

for source in ${(k)symlinks}; do
  dest=$symlinks[$source]
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
