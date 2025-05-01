#!/bin/bash
# jaja-agent/scripts/01_analyze_and_prepare.sh
# Анализ аппаратной информации и подготовка параметров

set -euo pipefail

CONFIG_FILE="/etc/jaja.conf"
LOG_DIR="/tmp/system_logs"
OUTPUT_ENV="/etc/jaja.env"

[[ -f "$CONFIG_FILE" ]] || { echo "❌ Конфиг $CONFIG_FILE не найден!"; exit 1; }
[[ -d "$LOG_DIR" ]]     || { echo "❌ Логи не найдены в $LOG_DIR"; exit 1; }

source "$CONFIG_FILE"

echo "🔍 Анализируем систему..."

# Извлечение vendor_id из лога lscpu
CPU_VENDOR=$(grep -i "vendor_id" "$LOG_DIR/lscpu.log" | head -n1 | sed 's/.*: //')
[[ -z "$CPU_VENDOR" ]] && { echo "❌ Не удалось определить вендора CPU"; exit 1; }

# Сохраняем определённый параметр
echo "cpu_vendor=$CPU_VENDOR" > "$OUTPUT_ENV"

echo "✅ CPU-вендор: $CPU_VENDOR"
echo "➡️ Сохранено в: $OUTPUT_ENV"

if [[ "${NOTIFY_ENABLED:-no}" == "yes" ]] && command -v notify-send &>/dev/null; then
    notify-send "JAJA" "Вендор CPU: $CPU_VENDOR"
fi
