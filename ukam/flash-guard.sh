#!/usr/bin/env bash
set -euo pipefail

name=${1:?mcu name required}
device=${2:?device path required}
shift 2

if [[ ! -e "$device" ]]; then
  echo "[UKAM] $name: device not present: $device"
  echo "[UKAM] Host transfer or USB wiring is not complete; flash command skipped."
  exit 0
fi

if [[ "${UKAM_ALLOW_FLASH:-0}" != "1" ]]; then
  echo "[UKAM] $name: dry-run guard active."
  echo "[UKAM] Would run: $*"
  echo "[UKAM] Re-run with UKAM_ALLOW_FLASH=1 only after confirming this MCU target."
  exit 0
fi

echo "[UKAM] $name: executing: $*"
exec "$@"
