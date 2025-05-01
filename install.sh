#!/bin/bash

# === Минимум для запуска: curl и gpg ===
for essential in curl gpg; do
  if ! command -v "$essential" &>/dev/null; then
    echo "[INFO] $essential не найден. Устанавливаю..."
    (command -v dnf5 &>/dev/null && sudo dnf5 install -y "$essential") || sudo dnf install -y "$essential" || {
        echo "[ОШИБКА] Не удалось установить $essential. Установите вручную."
        exit 1
    }
  fi
done

set -euo pipefail

# Цвета
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
error()   { echo -e "${RED}[ОШИБКА]${NC} $1" >&2; exit 1; }
warning() { echo -e "${YELLOW}[ПРЕДУПРЕЖДЕНИЕ]${NC} $1"; }
success() { echo -e "${GREEN}[УСПЕХ]${NC} $1"; }

check_root() {
    [[ $EUID -ne 0 ]] && error "Скрипт должен запускаться от root. Используйте sudo."
}

install_deps() {
    echo "📦 Проверка и установка зависимостей..."
    local deps=(
        jq libnotify systemd dnf dnf5 inxi
        alsa-utils alsa-tools hda-verb
        pptp ppp NetworkManager-pptp NetworkManager-pptp-gnome
        policycoreutils-python-utils
    )
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            warning "Установка: $dep"
            (command -v dnf5 &>/dev/null && dnf5 install -y "$dep") || dnf install -y "$dep" || error "Не удалось установить $dep"
        fi
    done
    success "Все зависимости установлены"
}

setup_config() {
    echo "🔐 Загрузка и расшифровка конфигурации JAJA..."
    local config_url="https://raw.githubusercontent.com/GoldenStiv-Fedora/jaja-agent/main/configs/jaja.conf.gpg"
    curl -sfLO "$config_url" || error "Не удалось скачать конфиг"

    read -rsp "Введите пароль для расшифровки: " password; echo
    gpg -d --batch --passphrase "$password" jaja.conf.gpg > /etc/jaja.conf 2>/dev/null || error "Ошибка расшифровки"
    chmod 600 /etc/jaja.conf
    rm -f jaja.conf.gpg
    success "Конфиг установлен: /etc/jaja.conf"
    unset password
}

install_scripts() {
    echo "⬇️ Установка JAJA-скриптов..."
    local base_url="https://raw.githubusercontent.com/GoldenStiv-Fedora/jaja-agent/main/scripts"
    local scripts=("00_fetch_logs.sh" "01_analyze_and_prepare.sh" "02_full_auto_setup.sh" "03_maintenance.sh" "auto_clean_logs.sh")

    mkdir -p /usr/local/bin
    for script in "${scripts[@]}"; do
        curl -sfLo "/usr/local/bin/$script" "$base_url/$script" || error "Ошибка скачивания $script"
        chmod +x "/usr/local/bin/$script"
    done

    # Дополнительные модули
    local mod_url="https://raw.githubusercontent.com/GoldenStiv-Fedora/jaja-agent/main/modules"
    local mods=("setup_vpn_pptp.sh" "huawei_audio_fix.sh")
    for mod in "${mods[@]}"; do
        curl -sfLo "/usr/local/bin/$mod" "$mod_url/$mod" || error "Ошибка скачивания $mod"
        chmod +x "/usr/local/bin/$mod"
    done

    # Автообновление
    curl -sfLo /usr/local/bin/jaja_auto_update.sh "https://raw.githubusercontent.com/GoldenStiv-Fedora/jaja-agent/main/updater/jaja_auto_update.sh" || error "Ошибка скачивания jaja_auto_update.sh"
    chmod +x /usr/local/bin/jaja_auto_update.sh

    success "Скрипты и модули установлены"
}

install_services() {
    echo "⚙️ Установка systemd-юнитов..."
    local base="https://raw.githubusercontent.com/GoldenStiv-Fedora/jaja-agent/main/service_files"
    local units=(
        fedora-auto-setup.service
        auto-clean-logs.service
        auto-clean-logs.timer
        jaja-auto-update.service
        jaja-auto-update.timer
    )

    mkdir -p /etc/systemd/system

    for unit in "${units[@]}"; do
        curl -sfLo "/etc/systemd/system/$unit" "$base/$unit" || error "Ошибка скачивания $unit"
    done

    systemctl daemon-reload
    systemctl enable --now fedora-auto-setup.service
    systemctl enable --now auto-clean-logs.timer
    systemctl enable --now jaja-auto-update.timer

    success "Systemd-сервисы JAJA активированы"
}

main() {
    check_root
    install_deps
    setup_config
    install_scripts
    install_services

    echo
    success "✅ Установка JAJA завершена!"
    echo "🔍 Проверить службу: systemctl status fedora-auto-setup.service"
    echo "⏱  Проверить таймеры: systemctl list-timers | grep jaja"
}

main
