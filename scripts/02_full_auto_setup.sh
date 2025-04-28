#!/bin/bash

CONFIG="/etc/fedora-setup.conf"
[[ -f "$CONFIG" ]] || { echo "❌ Конфиг не найден!"; exit 1; }
source "$CONFIG"

LOG_DIR="/var/log/fedora-auto-setup"
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/setup-$(date +%F).log") 2>&1

notify() {
    [[ "$NOTIFY_ENABLED" == "yes" ]] && notify-send "Fedora Setup" "$1"
}

echo "=== Starting Fedora Setup ==="
notify "Начало настройки системы"

{
    echo "1. Сбор информации..."
    /usr/local/bin/00_fetch_logs.sh

    echo "2. Анализ конфигурации..."
    /usr/local/bin/01_analyze_and_prepare.sh
    source /tmp/system_config_detected.conf

    echo "3. Применение профиля питания..."
    if [[ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" == "1" ]]; then
        tuned-adm profile balanced
        notify "Установлен профиль: Сбалансированный"
    else
        tuned-adm profile powersave
        notify "Установлен профиль: Энергосбережение"
    fi

    echo "4. Настройка сети и ядра..."
    sysctl -w net.core.default_qdisc=fq_codel
    sysctl -w net.ipv4.tcp_congestion_control=bbr

    echo "5. Перезапуск аудиосервисов..."
    systemctl --user restart pipewire{,-pulse}.service wireplumber.service || true

    echo "6. Включение таймера очистки логов..."
    systemctl enable --now auto-clean-logs.timer

    echo "=== Fedora Setup успешно завершен ==="
    notify "Настройка завершена"
} || {
    echo "❌ Ошибка настройки!"
    notify "Ошибка настройки"
    exit 1
}

[[ "$1" == "--daemon" ]] && sleep infinity
