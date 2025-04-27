#!/bin/bash

# Основной скрипт настройки Fedora
# Версия 3.0

# Режим работы
DAEMON_MODE=false
if [[ "$1" == "--daemon" ]]; then
    DAEMON_MODE=true
fi

# Загрузка конфига
CONFIG="/etc/fedora-setup.conf"
if [[ ! -f "$CONFIG" ]]; then
    echo "Конфигурационный файл не найден!" >&2
    exit 1
fi
source "$CONFIG"

# Логирование
LOG_DIR="/var/log/fedora-auto-setup"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup-$(date +%Y%m%d).log"

# Функция логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Основные задачи
run_tasks() {
    log "=== Запуск задач настройки ==="
    
    # 1. Сбор логов
    /usr/local/bin/00_fetch_logs.sh
    
    # 2. Анализ системы
    /usr/local/bin/01_analyze_and_prepare.sh
    
    # 3. Применение настроек
    source /tmp/system_config_detected.conf
    
    log "Применяем настройки для: CPU-$CPU_VENDOR, GPU-$GPU_VENDOR"
    
    # Здесь добавляйте ваши настройки...
    
    log "=== Задачи завершены ==="
}

# Режим демона
if "$DAEMON_MODE"; then
    log "Запуск в режиме демона"
    while true; do
        run_tasks
        sleep 3600  # Проверка каждый час
    done
else
    # Однократный запуск
    run_tasks
fi
