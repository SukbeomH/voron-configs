#!/bin/bash

# 설정 폴더로 이동
cd ~/printer_data/config

# 변경사항 모두 추가
git add .

# 커밋 (현재 날짜와 시간 메시지 포함)
current_date=$(date +"%Y-%m-%d %H:%M:%S")
git commit -m "Backup triggered on $current_date"

# 깃허브로 푸시
git push origin master