#!/usr/bin/env zsh
# List IOMMU groups for this system.
#
# DEPENDENCIES:
#   lspci    (pkgs.pciutils)

for d in /sys/kernel/iommu_groups/*/devices/*; do
  n=${d#*/iommu_groups/*}
  n=${n%%/*}
  printf 'IOMMU Group %s ' "$n"
  lspci -nns "${d##*/}"
done
