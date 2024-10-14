#!/usr/bin/env bash

if [ `uname` = Darwin ]; then
  launchctl unload ~/Library/LaunchAgents/system-info.plist
  rm ~/Library/LaunchAgents/system-info.plist
else
  if [ "$WSL_DISTRO_NAME" = "" ]; then
    systemctl --user stop system-info
    systemctl --user disable system-info
  else
    echo -e "\033[0;33mwarning:\033[0m WSL detected, system-info systemd service disabled"
  fi
fi
