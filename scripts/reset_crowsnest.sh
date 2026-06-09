#!/bin/sh
set -eu

sudo -n /usr/bin/systemctl reset-failed crowsnest
sudo -n /usr/bin/systemctl restart crowsnest
sleep 2
/usr/bin/systemctl --no-pager --full is-active crowsnest
