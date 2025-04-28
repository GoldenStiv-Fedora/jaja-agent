#!/bin/bash
# 00_fetch_logs.sh — Сбор логов системы

CONFIG_FILE="/etc/fedora-setup.conf"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Ошибка: конфиг $CONFIG_FILE не найден!" >&2
    exit 1
fi
source "$CONFIG_FILE"  # Подключаем настройки

LOG_DIR="/tmp/system_logs"
mkdir -p "$LOG_DIR"

upload_to_github() {
    local file_name="log_$(date +"%Y%m%d_%H%M%S")_$(sha256sum "$1" | cut -c1-8).log"
    curl -s -X PUT \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"message\":\"[LOG] $file_name\", \"content\":\"$(base64 -w0 "$1")\"}" \
        "https://api.github.com/repos/$GITHUB_USER/$GITHUB_LOG_REPO/contents/logs/$file_name"
}

# Сбор логов
lscpu | awk '{print NR ": " $0}' > "$LOG_DIR/lscpu.log"
lsblk -o NAME,SIZE,TYPE > "$LOG_DIR/lsblk.log"

# Отправка логов на GitHub
for file in "$LOG_DIR"/*.log; do
    upload_to_github "$file"
done
