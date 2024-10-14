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

if cat /proc/cpuinfo | grep -i intel > /dev/null; then
  cpu_temp_sensor="/intelcpu/0/temperature/0"
elif cat /proc/cpuinfo | grep -i amd > /dev/null; then
  cpu_temp_sensor="/amdcpu/0/temperature/0"
else
  return 1
fi

powershell="/mnt/c/Windows/System32/WindowsPowerShell/v1.0//powershell.exe"

while true; do
  # Assumes OpenHardwareMonitor is running and emitting data to WMI so we can
  # access it via the Windows hosts powershell.exe.
  raw_cpu_temp=$($powershell -NoProfile \
    "(Get-WmiObject -Namespace \"root/OpenHardwareMonitor\" -Query 'select Value from Sensor WHERE Identifier LIKE \"$cpu_temp_sensor\"').Value" \
    | sed 's/\r//')
  cpu_temp=$(printf "%.1f°C" "$raw_cpu_temp")

  cpu_load=" `mpstat -P ALL -n 1 -u 1 -o JSON | \
    jq '.sysstat.hosts[0].statistics[0]["cpu-load"][1:]|.[].idle' | \
    awk '$idle ~ /[-.0-9]*/ { printf "%s", substr("█▇▆▅▄▃▂▁ ", int($idle / 11), 1) }'`"

  raw_battery=$($powershell -NoProfile \
    "(Get-WmiObject win32_battery).EstimatedChargeRemaining" \
    | sed 's/\r//')
  if [ "" != "$raw_battery" ]; then
    battery="$(echo $raw_battery | awk '$battery ~ /.*/ {
      printf " %d%% %s\n", $battery, substr("", int($battery / 9), 1)
    }')"
  fi

  echo "$cpu_temp$cpu_load$battery" > $cache_file
  # echo "$(locale)" > $cache_file
  sleep 2
done
