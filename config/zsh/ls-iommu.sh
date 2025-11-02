#!/bin/bash
for d in /sys/kernel/iommu_groups/*/devices/*; do
  n=${d#*/iommu_groups/*}; n=${n%%/*}
  printf '%s ' "$n"
  lspci -nns "${d##*/}"
done
