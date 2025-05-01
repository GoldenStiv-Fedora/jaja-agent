#!/bin/bash
# jaja-agent/scripts/03_maintenance.sh
# Еженедельное обслуживание системы JAJA: обновления, логирование, анализ

set -euo pipefail

CONFIG="/etc/jaja.conf"
[[ -f "$CONFIG" ]] || { echo "❌ Конфиг не найден: $CONFIG"; exit 1; }
source "$CONFIG"

LOG_DIR="/var/log/jaja"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/maintenance-$(date +%F_%H-%M-%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

notify() {
    [[ "${NOTIFY_ENABLED:-no}" == "yes" ]] && command -v notify-send &>/dev/null && notify-send "JAJA Maintenance" "$1"
}

echo "🔄 === Еженедельная проверка JAJA ==="
notify "Запуск еженедельной проверки системы"

{
    echo "📦 Проверка и установка обновлений..."
    (command -v dnf5 &>/dev/null && dnf5 upgrade --refresh -y) || dnf upgrade --refresh -y || echo "⚠️ Не удалось обновить систему"

    echo "📝 Повторный сбор логов..."
    /usr/local/bin/00_fetch_logs.sh || echo "⚠️ Сбор логов завершился с ошибкой"

    echo "🧠 Повторный анализ системы..."
    /usr/local/bin/01_analyze_and_prepare.sh || echo "⚠️ Анализ завершился с ошибкой"

    echo "📋 Аудит системных ошибок..."
    systemctl --failed || true
    journalctl -p err -n 20 || true

    notify "JAJA: Еженедельная проверка завершена"
    echo "✅ Обслуживание завершено"
} || {
    echo "❌ Ошибка при обслуживании"
    notify "JAJA: Обслуживание завершилось с ошибкой"
    exit 1
}
