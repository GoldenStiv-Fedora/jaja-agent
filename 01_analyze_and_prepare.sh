#!/bin/bash

####################################################################
# 01_analyze_and_prepare.sh — АНАЛИЗ ЛОГОВ И НАСТРОЙКА              #
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
notify-send --urgency=low "🔍 Fedora Setup" "Анализ системных логов..."

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
}

{
    echo "[$(date)] Анализ конфигурации системы..."
    CPU_VENDOR=$(grep 'Vendor ID:' "$LOG_DIR/lscpu.log" | awk '{print $3}')
    GPU_VENDOR=$(grep -i 'VGA' "$LOG_DIR/lspci.log" | grep -oE 'Intel|NVIDIA|AMD')
    HAS_NVME=$(grep -i 'nvme' "$LOG_DIR/lsblk.log" && echo "yes" || echo "no")

    # Сохранение конфигурации
    CONFIG_FILE="/tmp/system_config_detected.conf"
    echo "cpu_vendor=$CPU_VENDOR" > "$CONFIG_FILE"
    echo "gpu_vendor=$GPU_VENDOR" >> "$CONFIG_FILE"
    echo "has_nvme=$HAS_NVME" >> "$CONFIG_FILE"

    # Загрузка результатов
    upload_to_github "$CONFIG_FILE"
} 2>&1 | tee -a "$SCRIPT_LOG"

# Итоговое уведомление
notify-send --urgency=normal "✅ Анализ завершен" \
"Конфигурация системы:\n• CPU: $CPU_VENDOR\n• GPU: $GPU_VENDOR\n• NVMe: $HAS_NVME\n\nЛоги: https://github.com/$GITHUB_USER/$GITHUB_REPO/logs"
echo "[$(date)] Завершение анализа." >> "$SCRIPT_LOG"
