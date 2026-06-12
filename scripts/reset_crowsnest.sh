#!/bin/sh
set -eu

curl -fsS \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"service":"crowsnest"}' \
  http://127.0.0.1:7125/machine/services/restart >/dev/null

sleep 2
/usr/bin/systemctl --no-pager --full is-active crowsnest
