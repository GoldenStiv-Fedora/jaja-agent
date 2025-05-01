#!/bin/bash
# jaja-agent/scripts/auto_clean_logs.sh
# Очистка устаревших логов JAJA

set -euo pipefail

CONFIG="/etc/jaja.conf"
[[ -f "$CONFIG" ]] || { echo "❌ Конфиг не найден: $CONFIG"; exit 1; }
source "$CONFIG"

[[ "${AUTO_CLEAN_LOGS:-no}" != "yes" ]] && exit 0

LOG_DIR="/var/log/jaja"
DAYS_KEEP="${MAX_LOG_AGE:-21}"

echo "🧹 Очистка логов старше $DAYS_KEEP дней в $LOG_DIR..."

find "$LOG_DIR" -type f -mtime +"$DAYS_KEEP" -exec rm -f {} \;

if [[ "${NOTIFY_ENABLED:-no}" == "yes" ]] && command -v notify-send &>/dev/null; then
    notify-send "JAJA" "Автоочистка логов выполнена"
fi

exit 0
