#!/usr/bin/env zsh

# Loop over available completions and add existing commands to array.
local -a completions
completions=(~/.config/zsh/zsh-completions/src/*)
local -a command_list
for completion in $completions; do
  local filename=$(basename $completion)
  local name=${filename:1}
  if command -v $name &> /dev/null; then
    command_list+=($name)
  fi
done

# Print JSON array of commands Ansible can consume.
echo '['
local length=${#command_list[@]}
for (( i = 1; i < $length; i++ )); do
  echo "  \"${command_list[$i]}\","
done
echo "  \"${command_list[-1]}\""
echo ']'
