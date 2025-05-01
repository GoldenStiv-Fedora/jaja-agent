#!/bin/bash
# jaja-agent/scripts/00_fetch_logs.sh
# Сбор системной информации — CPU, диски, устройства, ошибки

set -euo pipefail

CONFIG_FILE="/etc/jaja.conf"
[[ ! -f "$CONFIG_FILE" ]] && { echo "❌ Конфиг $CONFIG_FILE не найден!"; exit 1; }
source "$CONFIG_FILE"

LOG_DIR="/tmp/system_logs"
mkdir -p "$LOG_DIR"

echo "📝 Сбор системной информации..."

# CPU
lscpu > "$LOG_DIR/lscpu.log" || echo "⚠️ Ошибка lscpu"
# Диски
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,UUID > "$LOG_DIR/lsblk.log" || echo "⚠️ Ошибка lsblk"
# Общая системная информация
inxi -Fxxxz > "$LOG_DIR/inxi_full.log" || echo "⚠️ inxi не установлен или не доступен"
# Журнал ядра
dmesg --level=err,warn > "$LOG_DIR/dmesg.log" || echo "⚠️ Ошибка dmesg"

echo "✅ Логи собраны в: $LOG_DIR"

[[ "$NOTIFY_ENABLED" == "yes" ]] && command -v notify-send &>/dev/null && \
    notify-send "JAJA" "Системные логи собраны"
