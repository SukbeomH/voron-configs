#!/bin/sh
set -eu

echo "== filtered /dev/serial/by-path/ =="

if [ ! -d /dev/serial/by-path ]; then
  echo "/dev/serial/by-path not found"
  exit 0
fi

for path_link in /dev/serial/by-path/*; do
  [ -L "$path_link" ] || continue

  case "$path_link" in
    *usbv2*)
      ;;
    *)
      continue
      ;;
  esac

  tty_target=$(readlink -f "$path_link")
  tty_name=$(basename "$tty_target")
  by_id_name=$(find /dev/serial/by-id -maxdepth 1 -type l -lname "*$tty_name" -printf '%f\n' 2>/dev/null | head -n 1 || true)

  case "$by_id_name" in
    *Klipper*|*Cartographer*|*FLY_BUFFER*)
      continue
      ;;
  esac

  ls -l "$path_link"
done
