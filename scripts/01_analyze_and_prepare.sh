#!/bin/bash
# jaja-agent/scripts/01_analyze_and_prepare.sh
# Анализ собранных логов и подготовка конфигурации системы

set -euo pipefail

LOG_DIR="/tmp/system_logs"
OUT_CONF="/etc/jaja.env"

[[ -d "$LOG_DIR" ]] || { echo "❌ Логи не найдены в $LOG_DIR"; exit 1; }

echo "🔍 Извлекаю информацию о системе..."

# Извлечение vendor_id из lscpu
CPU_VENDOR=$(grep -i "vendor_id" "$LOG_DIR/lscpu.log" | head -n1 | sed 's/.*: //')
[[ -z "$CPU_VENDOR" ]] && { echo "❌ Не удалось определить вендора CPU"; exit 1; }

# Пример дополнительной обработки: можно расширять
echo "cpu_vendor=$CPU_VENDOR" > "$OUT_CONF"

echo "✅ CPU-вендор определён: $CPU_VENDOR"
echo "➡️ Конфигурация записана в $OUT_CONF"

[[ "$NOTIFY_ENABLED" == "yes" ]] && command -v notify-send &>/dev/null && \
    notify-send "JAJA" "Определён CPU-вендор: $CPU_VENDOR"
