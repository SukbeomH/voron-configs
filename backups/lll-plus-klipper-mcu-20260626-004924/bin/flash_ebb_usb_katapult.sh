#!/usr/bin/env bash
set -euo pipefail

KLIPPER_DEV="/dev/serial/by-id/usb-Klipper_stm32g0b1xx_500031000650505539323520-if00"

cp /home/sukbeom/klipper-kconfigs/ebb36_42_g0b1_usb_katapult.config /home/sukbeom/klipper/.config
cd /home/sukbeom/klipper
make clean
make

if [[ -e "$KLIPPER_DEV" ]]; then
  FLASH_DEVICE="$KLIPPER_DEV"
else
  echo "ERROR: EBB USB device not found."
  echo "Expected:"
  echo "  $KLIPPER_DEV"
  echo
  ls -l /dev/serial/by-id/ 2>/dev/null || true
  exit 2
fi

echo "Using EBB flash device: $FLASH_DEVICE"

service klipper stop || true
make flash FLASH_DEVICE="$FLASH_DEVICE"
service klipper start || true
