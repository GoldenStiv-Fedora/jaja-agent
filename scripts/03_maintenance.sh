#!/bin/bash

CONFIG="/etc/fedora-setup.conf"
[[ -f "$CONFIG" ]] || { echo "❌ Конфиг не найден!"; exit 1; }
source "$CONFIG"

notify() {
    [[ "$NOTIFY_ENABLED" == "yes" ]] && notify-send "Fedora Setup Maintenance" "$1"
}

echo "=== Еженедельная проверка системы ==="

dnf5 check-update --refresh && dnf5 upgrade -y

/usr/local/bin/00_fetch_logs.sh
/usr/local/bin/01_analyze_and_prepare.sh

notify "Еженедельная проверка и обновление завершено."
