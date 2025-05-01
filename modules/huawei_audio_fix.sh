#!/bin/bash
# jaja-agent/modules/huawei_audio_fix.sh
# Huawei MateBook HKF-WXX: установка аудиофикса только при точном совпадении

set -euo pipefail

CONFIG="/etc/jaja.conf"
[[ -f "$CONFIG" ]] || { echo "❌ Конфиг $CONFIG не найден!"; exit 1; }
source "$CONFIG"

MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "UNKNOWN")
SERIAL=$(cat /sys/class/dmi/id/product_serial 2>/dev/null || echo "UNKNOWN")

if [[ "$ALLOW_HUAWEI_FIX" != "yes" ]]; then
    echo "⛔ Huawei fix отключён в конфиге"
    exit 0
fi

if [[ "$MODEL" != "$HUAWEI_MODEL" || "$SERIAL" != "$HUAWEI_SERIAL" ]]; then
    echo "ℹ️ Устройство не требует Huawei audio fix"
    echo "  → Модель: $MODEL"
    echo "  → Серийник: $SERIAL"
    exit 0
fi

echo "🛠️ Установка Huawei Audio Jack Fix..."
dnf install -y alsa-utils alsa-tools hda-verb || echo "⚠️ Не удалось установить ALSA-пакеты"

# Копируем скрипт и юнит
install -Dm755 /usr/local/share/jaja/drivers/huawei-audio-fix/huawei-soundcard-headphones-monitor.sh /usr/local/bin/huawei-soundcard-headphones-monitor.sh
install -Dm644 /usr/local/share/jaja/drivers/huawei-audio-fix/huawei-soundcard-headphones-monitor.service /etc/systemd/system/huawei-soundcard-headphones-monitor.service

# Активация
systemctl daemon-reload
systemctl enable --now huawei-soundcard-headphones-monitor.service

echo "✅ Huawei Audio Jack Monitor успешно установлен и запущен"
