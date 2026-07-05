#!/bin/bash
set -e

# 설정 폴더로 이동
cd ~/printer_data/config

# 공개 repo에 올릴 설정 파일만 명시적으로 추가.
# Klipper macro가 `sh autocommit.sh`로 실행하므로 POSIX sh 문법만 사용한다.
for file in \
  .gitignore \
  autocommit.sh \
  lll_plus.cfg \
  macros.cfg \
  mainsail.cfg \
  moonraker.conf \
  moonraker-obico-update.cfg \
  moonraker-obico.example.cfg \
  moonraker_obico_macros.cfg \
  printer.cfg \
  printer_bd_pressure_usb.cfg \
  printer_bdwidth.cfg \
  printer_bme280_toolhead.cfg \
  printer_cartographer.cfg \
  printer_homing.cfg \
  printer_mainboard.cfg \
  printer_toolhead_usb.cfg \
  update_plr.cfg
do
  if [ -e "$file" ]; then
    git add "$file"
  fi
done

if [ -d docs ]; then
  find docs -type f -name '*.md' -print0 | xargs -0 -r git add
fi

if [ -f context/README.md ]; then
  git add context/README.md
fi

# live-only/runtime/generated 파일은 절대 커밋하지 않음
git reset -q -- moonraker-obico.cfg .moonraker.conf.bkp variables.cfg backups ShakeTune_results chopper_magnitude 'printer-*.cfg' 'backup-mainsail_*.json' 2>/dev/null || true

if git diff --cached --quiet; then
  echo "No public config changes to commit."
  exit 0
fi

# 커밋 (현재 날짜와 시간 메시지 포함)
current_date=$(date +"%Y-%m-%d %H:%M:%S")
git commit -m "Backup triggered on $current_date"

# 원격 변경을 반영해서 non-fast-forward push를 방지
git fetch origin master
git rebase --autostash origin/master

# 깃허브로 푸시
git push origin master
