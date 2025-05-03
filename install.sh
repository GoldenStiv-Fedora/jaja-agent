#!/usr/bin/env bash

# === ГЛАВНЫЙ СКРИПТ УСТАНОВКИ JAJA ===
# ПОЛНОСТЬЮ АВТОМАТИЗИРОВАННАЯ УСТАНОВКА И НАСТРОЙКА НА ОСНОВАНИИ ПРЕДОСТАВЛЕННОГО КОНФИГА

set -euo pipefail

# === ЗАГРУЗКА И РАСШИФРОВКА КОНФИГА ===
CONFIG_DECRYPTED_PATH="/tmp/jaja.conf"  # временный путь для расшифрованного файла
GPG_ENCRYPTED_CONFIG="$(dirname "$0")/configs/jaja.conf.gpg"  # путь к зашифрованному конфигу

gpg --quiet --batch --yes --decrypt --output "$CONFIG_DECRYPTED_PATH" "$GPG_ENCRYPTED_CONFIG"  # расшифровываем конфиг
source "$CONFIG_DECRYPTED_PATH"  # загружаем переменные из конфига

# === СОЗДАНИЕ КАТАЛОГА ДЛЯ ЛОГОВ ===
LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"

# === ФУНКЦИЯ ДЛЯ УВЕДОМЛЕНИЙ И ВЫВОДА СООБЩЕНИЙ ===
notify() {
    if [[ "$NOTIFY_ENABLED" == "yes" ]]; then
        notify-send -u normal -a "JAJA" "$1"  # отправка графического уведомления через notify-send
    fi
    echo "[JAJA] $1"  # дублирование сообщения в терминал
}

# === ПРОВЕРКА И УСТАНОВКА ЗАВИСИМОСТЕЙ ===
notify "Проверка и установка необходимых зависимостей..."
REQUIRED_PKGS=(gpg systemd systemd-udev systemd-libs wget curl gnupg2 util-linux coreutils tar sed grep awk)
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! rpm -q "$pkg" &>/dev/null; then
        notify "Пакет $pkg не установлен. Выполняется установка..."
        sudo dnf install -y "$pkg"
    fi
done

# === ОПРЕДЕЛЕНИЕ ИНФОРМАЦИИ О СИСТЕМЕ ===
OS_VERSION=$(cat /etc/fedora-release)  # определяем версию Fedora
HOST_TYPE="$(hostnamectl | grep 'Chassis' | awk '{print tolower($2)}')"  # тип устройства: laptop, desktop, server
MACHINE_MODEL=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null || echo "unknown")  # модель устройства

notify "Обнаружена Fedora: $OS_VERSION"
notify "Тип устройства: $HOST_TYPE (Модель: $MACHINE_MODEL)"

# === ВЫБОР СТРАТЕГИИ НАСТРОЙКИ В ЗАВИСИМОСТИ ОТ УСТРОЙСТВА ===
if [[ "$HOST_TYPE" == "laptop" ]]; then
    STRATEGY="laptop"
elif [[ "$HOST_TYPE" == "desktop" ]]; then
    STRATEGY="desktop"
elif [[ "$HOST_TYPE" == "server" ]]; then
    STRATEGY="server"
else
    STRATEGY="generic"
fi

notify "Выбрана стратегия настройки: $STRATEGY"

# === УСТАНОВКА FIX'А ДЛЯ ЗВУКА НА НОУТБУКАХ HUAWEI ===
apply_huawei_audio_fix() {
    notify "Применяется аудио-фикс Huawei..."
    cp -v "$(dirname "$0")/drivers/huawei-audio-fix/huawei-soundcard-headphones-monitor."* /etc/systemd/system/
    cp -v "$(dirname "$0")/modules/huawei_audio_fix.sh" /usr/local/bin/
    chmod +x /usr/local/bin/huawei_audio_fix.sh
    systemctl daemon-reexec
    systemctl enable --now huawei-soundcard-headphones-monitor.service
    notify "Аудио-фикс Huawei установлен и активирован."
}

# === УСЛОВНАЯ УСТАНОВКА ДРАЙВЕРА HUAWEI ===
if [[ "$ALLOW_HUAWEI_FIX" == "yes" && "$HUAWEI_MODEL" == "$MACHINE_MODEL" ]]; then
    apply_huawei_audio_fix
else
    notify "Аудио-фикс Huawei пропущен (не требуется для данной модели)."
fi

# === НАСТРОЙКА VPN ===
if [[ "$ENABLE_VPN_SETUP" == "yes" ]]; then
    notify "Настройка VPN (PPTP)..."
    bash "$(dirname "$0")/modules/setup_vpn_pptp.sh"
fi

# === УСТАНОВКА СЛУЖБЫ АВТОЧИСТКИ ЛОГОВ ===
if [[ "$AUTO_CLEAN_LOGS" == "yes" ]]; then
    notify "Установка службы автоочистки логов..."
    cp "$(dirname "$0")/service_files/auto-clean-logs."* /etc/systemd/system/
    systemctl daemon-reexec
    systemctl enable --now auto-clean-logs.timer
fi

# === УСТАНОВКА СЛУЖБЫ АВТООБНОВЛЕНИЯ ===
if [[ "$JAJA_AUTO_UPDATE" == "yes" ]]; then
    notify "Установка службы автообновления..."
    cp -v "$(dirname "$0")/updater/jaja_auto_update.sh" /usr/local/bin/
    chmod +x /usr/local/bin/jaja_auto_update.sh
    cp "$(dirname "$0")/service_files/jaja-auto-update."* /etc/systemd/system/
    systemctl daemon-reexec
    systemctl enable --now jaja-auto-update.timer
fi

# === ЗАПУСК ПОЛНОЙ НАСТРОЙКИ ПОСЛЕ УСТАНОВКИ ===
if [[ "$RUN_FULL_SETUP_AFTER_INSTALL" == "yes" ]]; then
    notify "Запуск полной автоматической настройки системы..."
    bash "$(dirname "$0")/scripts/02_full_auto_setup.sh"
fi

# === УДАЛЕНИЕ ВРЕМЕННОГО КОНФИГА ===
rm -f "$CONFIG_DECRYPTED_PATH"
notify "Установка и начальная настройка JAJA завершены."

exit 0
