#!/usr/bin/env bash
set -euo pipefail

PORT="${MANTA_PORT:-/dev/serial/by-path/platform-fd500000.pcie-pci-0000:01:00.0-usb-0:1.3:1.0-port0}"
FW="${1:-/home/sukbeom/klipper/out/klipper.bin}"
STM32LOADER="${STM32LOADER:-/home/sukbeom/.local/bin/stm32loader}"
APP_ADDR="${APP_ADDR:-0x08000000}"



cp ~/klipper-kconfigs/m8p_uart_noboot.config ~/klipper/.config
cd ~/klipper
make clean
make


if [[ ! -e "$PORT" ]]; then
  echo "ERROR: Manta UART port not found: $PORT" >&2
  echo "Current serial paths:" >&2
  ls -l /dev/serial/by-path/ 2>/dev/null || true
  exit 2
fi

if [[ ! -s "$FW" ]]; then
  echo "ERROR: firmware file missing or empty: $FW" >&2
  exit 2
fi

if [[ ! -x "$STM32LOADER" ]]; then
  echo "ERROR: stm32loader not executable: $STM32LOADER" >&2
  exit 2
fi

echo "Using Manta UART port: $PORT"
echo "Using firmware: $FW"

sudo service klipper stop || true
sleep 2

if [[ "${M8P_MANUAL_BOOT:-0}" != "1" ]]; then
  echo "Requesting serial bootloader via Klipper physical serial request..."

  python3 - "$PORT" <<'PY'
import sys
import time
import serial

port = sys.argv[1]

with serial.Serial(port, 250000, timeout=0.5) as s:
    s.write(b"~ \x1c Request Serial Bootloader!! ~")
    s.flush()

time.sleep(2)
PY

else
  echo "Manual bootloader mode selected."
  echo "Make sure BOOT0 + RESET was already performed."
fi

echo "Flashing Manta M8P V2 via STM32 ROM UART bootloader..."

"$STM32LOADER" \
  -p "$PORT" \
  -e -w -v \
  -a "$APP_ADDR" \
  -g "$APP_ADDR" \
  "$FW"

echo "Flash complete."

echo "Reset or power-cycle Manta, then run:"

echo "  sudo service klipper start"
