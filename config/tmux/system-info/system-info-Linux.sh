#!/usr/bin/env bash

cache_dir=~/.cache/tmux
cache_file=$cache_dir/system-info

# Make sure the output directory exists.
if [ ! -d $cache_dir ]; then
  mkdir -p $cache_dir
fi

if command -v sensors &> /dev/null; then
  if sensors 'coretemp-isa-0000' &> /dev/null; then
    function get_cpu_temp() {
      sensors 'coretemp-isa-0000' | awk 'NR == 3 { print $4 }'
    }
  elif sensors 'k10temp-pci-00c3' &> /dev/null; then
    function get_cpu_temp {
      sensors 'k10temp-pci-00c3' | grep 'Tctl:' | awk '{ print $2 }'
    }
  else
    function get_cpu_temp {
      echo ''
    }
  fi
else
  function get_cpu_temp {
    echo 'N/A°C'
  }
fi

if upower -e | grep 'BAT' 2> /dev/null; then
  function get_battery {
    local output=$(acpi -b)
    local charging=$(echo $output | awk '{ print $3 }')
    local percentage=$(echo $output | awk '{ print $4 }')
    if [ "$charging" = "Charging," ];then
      echo $percentage | awk '$battery ~ /.*/ {
        printf " %d%% %s\n", $battery, substr("󰢟󰢜󰂆󰂇󰂈󰢝󰂉󰢞󰂊󰂋󰂅", int($battery / 9), 1)
      }'
    else
      echo $percentage | awk '$battery ~ /.*/ {
        printf " %d%% %s\n", $battery, substr("󰂎󰁺󰁻󰁼󰁽󰁾󰁿󰂀󰂁󰂂󰁹", int($battery / 9), 1)
      }'
    fi
  }
else
  function get_battery {
    echo ''
  }
fi

# Cleanup cache file when interrupted.
trap '[ -f $cache_file ] && rm $cache_file; exit' INT
trap '[ -f $cache_file ] && rm $cache_file; exit' TERM

while true; do
  # Parse the current CPU load on all cores/threads.
  cpu_load=" `mpstat -P ALL -n 1 -u 1 -o JSON | \
    jq '.sysstat.hosts[0].statistics[0]["cpu-load"][1:]|.[].idle' | \
    awk '$idle ~ /[-.0-9]*/ { printf "%s", substr("█▇▆▅▄▃▂▁ ", int($idle / 11), 1) }'`"

  # Parse the current CPU package temperature.
  cpu_temp=$(get_cpu_temp)

  # Get the battery status if present.
  battery=$(get_battery)

  # Write to the cache file.
  echo "$cpu_temp$cpu_load$battery" > $cache_file
done
