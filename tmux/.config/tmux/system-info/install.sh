#!/usr/bin/env bash

script_dir=`dirname $0`

if [ `uname` = Darwin ]; then
  cp $script_dir/system-info.plist ~/Library/LaunchAgents/system-info.plist
  launchctl load -w ~/Library/LaunchAgents/system-info.plist
else
  if [ "$WSL_DISTRO_NAME" = "" ]; then
    cp $script_dir/system-info.service ~/.config/systemd/user/system-info.service
    systemctl --user enable system-info
    systemctl --user start system-info
  else
    echo -e "\033[0;33mwarning:\033[0m WSL detected, system-info systemd service disabled"
  fi
fi
