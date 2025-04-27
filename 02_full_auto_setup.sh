#!/bin/bash

# Основной скрипт с улучшенной обработкой для systemd
CONFIG="/etc/fedora-setup.conf"
[ -f "$CONFIG" ] || { echo "Config not found!"; exit 1; }
source "$CONFIG"

# Логирование
LOG_DIR="/var/log/fedora-auto-setup"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/setup-$(date +%F).log") 2>&1

# Функция для отправки уведомлений
notify() {
    [ "$NOTIFY_ENABLED" = "yes" ] && notify-send "Fedora Setup" "$1"
}

echo "=== Starting Fedora Setup ==="
notify "Начало настройки системы"

# Основные этапы
{
    echo "1. Сбор информации о системе..."
    /usr/local/bin/00_fetch_logs.sh
    
    echo "2. Анализ конфигурации..."
    /usr/local/bin/01_analyze_and_prepare.sh
    source /tmp/system_config_detected.conf
    
    echo "3. Применение настроек..."
    # Ваши настройки здесь
    
    echo "=== Настройка завершена ==="
    notify "Настройка системы завершена"
} || {
    echo "Ошибка в процессе настройки!"
    notify "Ошибка настройки"
    exit 1
}

# Для режима демона
if [[ "$1" == "--daemon" ]]; then
    echo "Режим демона: ожидание следующего запуска..."
    sleep infinity
fi
