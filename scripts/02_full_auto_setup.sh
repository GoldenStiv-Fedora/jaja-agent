#!/bin/bash
# 02_full_auto_setup.sh — Полная автоматизация настройки Fedora

CONFIG="/etc/fedora-setup.conf"
[ -f "$CONFIG" ] || { echo "Config not found!"; exit 1; }
source "$CONFIG"

LOG_DIR="/var/log/fedora-auto-setup"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/setup-$(date +%F).log") 2>&1

notify() {
    [ "$NOTIFY_ENABLED" = "yes" ] && notify-send "Fedora Setup" "$1"
}

echo "=== Starting Fedora Setup ==="
notify "Начало настройки системы"

{
    echo "1. Сбор логов..."
    /usr/local/bin/00_fetch_logs.sh

    echo "2. Анализ системы..."
    /usr/local/bin/01_analyze_and_prepare.sh
    source /tmp/system_config_detected.conf

    echo "3. Применение оптимизаций..."
    # Здесь будет установка оптимизаций под систему
    notify "Настройка завершена"
} || {
    echo "Ошибка при выполнении автоматизации!"
    notify "Ошибка настройки"
    exit 1
}

if [[ "$1" == "--daemon" ]]; then
    echo "Работа в режиме демона. Ожидание..."
    sleep infinity
fi
