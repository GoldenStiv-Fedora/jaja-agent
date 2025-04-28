#!/bin/bash

CONFIG="/etc/fedora-setup.conf"
[[ -f "$CONFIG" ]] || { echo "❌ Конфиг не найден!"; exit 1; }
source "$CONFIG"

[[ "$AUTO_CLEAN_LOGS" != "yes" ]] && exit 0

DAYS_KEEP="${MAX_LOG_AGE:-21}"
find /var/log/fedora-auto-setup/ -type f -mtime +$DAYS_KEEP -exec rm -f {} \;

[[ "$NOTIFY_ENABLED" == "yes" ]] && notify-send "Fedora Setup" "Автоочистка логов выполнена"
exit 0
