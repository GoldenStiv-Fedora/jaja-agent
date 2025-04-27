#!/bin/bash

####################################################################
# 02_full_auto_setup.sh — АВТОМАТИЧЕСКАЯ НАСТРОЙКА FEDORA           #
# Логи: https://github.com/GoldenStiv-Fedora/fedora-setup/logs      #
####################################################################

# Загрузка конфигурации
CONFIG_FILE="/etc/fedora-setup.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Ошибка: файл конфигурации $CONFIG_FILE не найден!" | tee -a /tmp/system_setup.log
    notify-send --urgency=critical "Ошибка" "Отсутствует конфигурационный файл!"
    exit 1
fi
source "$CONFIG_FILE"

GITHUB_RAW="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/main"
GITHUB_API="https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents"
SCRIPT_LOG="/tmp/system_setup.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

# Уведомление о начале
notify-send --urgency=critical "🚀 Fedora Setup" "Начало автоматической настройки системы!"

# Проверка обновлений скрипта
check_updates() {
    local script_name=$(basename "$0")
    local remote_sha=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "$GITHUB_API/$script_name" | jq -r '.sha')
    local local_sha=$(sha256sum "$0" | awk '{print $1}')

    if [[ "$remote_sha" != "$local_sha" ]]; then
        curl -s -H "Authorization: token $GITHUB_TOKEN" \
            "$GITHUB_API/$script_name" | jq -r '.content' | base64 -d > "$0"
        chmod +x "$0"
        notify-send --urgency=critical "🔁 Скрипт обновлён" "Перезапустите скрипт вручную."
        exit 0
    fi
}

# Очистка старых логов (старше 3 недель)
clean_old_logs() {
    local logs=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "$GITHUB_API/logs" | jq -r '.[] | select(.type == "file") | .name')

    for log in $logs; do
        log_date=$(echo "$log" | grep -oE "[0-9]{4}-[0-9]{2}-[0-9]{2}")
        if [[ $(date -d "$log_date" +%s) -lt $(date -d "3 weeks ago" +%s) ]]; then
            curl -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
                "$GITHUB_API/logs/$log"
            echo "🗑️ Удалён старый лог: $log"
        fi
    done
}

# Основной процесс
{
    check_updates
    clean_old_logs

    # Загрузка и запуск зависимостей
    curl -s -o "/tmp/00_fetch_logs.sh" "$GITHUB_RAW/00_fetch_logs.sh"
    chmod +x "/tmp/00_fetch_logs.sh"
    /tmp/00_fetch_logs.sh

    curl -s -o "/tmp/01_analyze_and_prepare.sh" "$GITHUB_RAW/01_analyze_and_prepare.sh"
    chmod +x "/tmp/01_analyze_and_prepare.sh"
    /tmp/01_analyze_and_prepare.sh

    # Применение настроек
    source /tmp/system_config_detected.conf
    dnf install -y powertop tuned thermald lm_sensors irqbalance nvme-cli
    tuned-adm profile powersave
    systemctl enable --now thermald irqbalance tuned
} 2>&1 | tee -a "$SCRIPT_LOG"

# Итоговое уведомление
notify-send --urgency=critical "🎉 Настройка завершена!" \
"Система оптимизирована:\n• CPU: $CPU_VENDOR\n• GPU: $GPU_VENDOR\n• NVMe: $HAS_NVME\n\nЛоги: https://github.com/$GITHUB_USER/$GITHUB_REPO/logs"
echo "[$(date)] Настройка системы завершена." >> "$SCRIPT_LOG"
