#!/bin/bash

####################################################################
# 00_fetch_logs.sh — СБОР ЛОГОВ С ЗАГРУЗКОЙ В GITHUB                #
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

LOG_DIR="/tmp/system_logs"
SCRIPT_LOG="/tmp/system_setup.log"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
GITHUB_API="https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/logs"

# Уведомление о начале
notify-send --urgency=low "🛠️ Fedora Setup" "Начался сбор системных логов..."

# Функция загрузки на GitHub
upload_to_github() {
    local file_path="$1"
    local file_name="${TIMESTAMP}_$(basename "$file_path")"
    local encoded_content=$(base64 -w 0 "$file_path")

    curl -s -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
            \"message\": \"[AUTO] Лог $file_name\",
            \"content\": \"$encoded_content\"
        }" \
        "$GITHUB_API/$file_name" | tee -a "$SCRIPT_LOG"
    echo "📤 Лог загружен: https://github.com/$GITHUB_USER/$GITHUB_REPO/logs/$file_name"
}

# Создание директории для логов
mkdir -p "$LOG_DIR"
echo "[$(date)] Начало сбора логов." > "$SCRIPT_LOG"

# Сбор логов
{
    echo "=== Сбор информации о системе ==="
    inxi -Fxxz > "$LOG_DIR/inxi_full.log"
    lshw > "$LOG_DIR/lshw_full.log"
    lscpu > "$LOG_DIR/lscpu.log"
    lsblk > "$LOG_DIR/lsblk.log"
    lsusb > "$LOG_DIR/lsusb.log"
    lspci -vvv > "$LOG_DIR/lspci.log"
    sensors > "$LOG_DIR/sensors.log"
    nvme list > "$LOG_DIR/nvme_list.log" 2>/dev/null || echo "ℹ️ Нет NVMe дисков"
    uname -a > "$LOG_DIR/uname.log"
    cat /etc/os-release > "$LOG_DIR/os-release.log"
} 2>&1 | tee -a "$SCRIPT_LOG"

# Загрузка логов
for log_file in "$LOG_DIR"/*; do
    upload_to_github "$log_file"
done

# Итоговое уведомление
notify-send --urgency=normal "✅ Сбор логов завершен" \
"Логи сохранены в GitHub:\nhttps://github.com/$GITHUB_USER/$GITHUB_REPO/logs\n\nПодробности в $SCRIPT_LOG"
echo "[$(date)] Логи собраны и загружены." >> "$SCRIPT_LOG"
