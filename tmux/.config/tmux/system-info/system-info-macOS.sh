#!/usr/bin/env bash

cache_dir=~/.cache/tmux
cache_file=$cache_dir/system-info

# Make sure the output directory exists.
if [ ! -d $cache_dir ]; then
  mkdir -p $cache_dir
fi

# Cleanup cache file when interrupted.
trap '[ -f $cache_file ] && rm $cache_file; exit' INT
trap '[ -f $cache_file ] && rm $cache_file; exit' TERM

# Check if a battery is installed.
ioreg -w0 -l | grep BatteryInstalled &> /dev/null && \
  has_battery=true || has_battery=false

while true; do
  # # Get the current CPU temperature.
  # cpu_temp="`/usr/local/bin/osx-cpu-temp`"

  cpu_load=$(sudo powermetrics --format text \
      --sample-rate 1200 --sample-count 1 --samplers cpu_power |
    grep --color=never -E 'CPU \d idle residency:' |
    grep --color=never -Eo '\d+\.\d+' |
    gawk '$idle ~ /[-.0-9]*/ { printf "%s", substr("█▇▆▅▄▃▂▁ ", int($idle / 10), 1) }'
  )

  # Parse the current battery charge percentage.
  if $has_battery; then
    raw_battery="$(pmset -g batt | \
      grep --color=never 'InternalBattery' | \
      grep --color=never -Eo '\d+%' | \
      grep --color=never -Eo '\d+')"
    battery="$(echo $raw_battery | gawk '$battery ~ /.*/ {
      printf " %d%% %s\n", $battery, substr("󰂎󰁺󰁻󰁼󰁽󰁾󰁿󰂀󰂁󰂂󰁹", int($battery / 9), 1)
    }')"
  fi

  # Write to the cache file.
  echo "$cpu_temp$cpu_load$battery" > $cache_file
done
