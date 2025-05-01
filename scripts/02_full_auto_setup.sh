#!/bin/bash
# jaja-agent/scripts/02_full_auto_setup.sh
# Основная логика настройки системы JAJA

set -euo pipefail

CONFIG="/etc/jaja.conf"
[[ -f "$CONFIG" ]] || { echo "❌ Конфиг не найден: $CONFIG"; exit 1; }
source "$CONFIG"

LOG_DIR="/var/log/jaja"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/setup-$(date +%F_%H-%M-%S).log"

# Вывод всего в лог
exec > >(tee -a "$LOG_FILE") 2>&1

notify() {
    [[ "${NOTIFY_ENABLED:-no}" == "yes" ]] && command -v notify-send &>/dev/null && notify-send "JAJA" "$1"
}

echo "🎛️ === Запуск JAJA Setup ==="
notify "Запущена автоматическая настройка системы"

{
    echo "📥 Сбор логов системы..."
    /usr/local/bin/00_fetch_logs.sh

    echo "🧠 Анализ конфигурации..."
    /usr/local/bin/01_analyze_and_prepare.sh
    source /etc/jaja.env

    echo "🔋 Настройка питания..."
    if [[ -f /sys/class/power_supply/AC/online ]] && [[ "$(cat /sys/class/power_supply/AC/online)" == "1" ]]; then
        tuned-adm profile balanced || true
        notify "Активирован профиль: balanced"
    else
        tuned-adm profile powersave || true
        notify "Активирован профиль: powersave"
    fi

    echo "🌐 Оптимизация сети..."
    sysctl -w net.core.default_qdisc=fq_codel || true
    sysctl -w net.ipv4.tcp_congestion_control=bbr || true

    echo "🔊 Перезапуск аудиосервисов..."
    systemctl --user restart pipewire{,-pulse}.service wireplumber.service || true

    echo "🧹 Активация автоочистки логов..."
    systemctl enable --now auto-clean-logs.timer || true

    echo "🎯 Проверка на Huawei..."
    if [[ "${ALLOW_HUAWEI_FIX}" == "yes" ]]; then
        MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
        SERIAL=$(cat /sys/class/dmi/id/product_serial 2>/dev/null || true)
        if [[ "$MODEL" == "$HUAWEI_MODEL" && "$SERIAL" == "$HUAWEI_SERIAL" ]]; then
            echo "🛠️ Установка Huawei fix..."
            bash /usr/local/bin/huawei_audio_fix.sh || echo "⚠️ Huawei fix завершился с ошибкой"
        else
            echo "ℹ️ Устройство не требует Huawei fix"
        fi
    fi

    echo "✅ Настройка JAJA завершена успешно"
    notify "JAJA: Настройка завершена"
} || {
    echo "❌ Произошла ошибка в процессе настройки!"
    notify "JAJA: Ошибка настройки"
    exit 1
}

[[ "$1" == "--daemon" ]] && sleep infinity
