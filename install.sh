#!/bin/bash

# JAJA — Интеллектуальный агент настройки Fedora
# Установка и первичная настройка

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
    local deps=("curl" "gpg" "jq" "libnotify" "systemd" "dnf" "dnf5" "inxi")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            warning "Установка зависимости: $dep"
            (command -v dnf5 &>/dev/null && dnf5 install -y "$dep") || dnf install -y "$dep" || error "Не удалось установить $dep"
        fi
    done
}

setup_config() {
    echo "🔐 Загрузка зашифрованного конфига..."
    local config_url="https://raw.githubusercontent.com/GoldenStiv-Fedora/jaja-agent/main/configs/jaja.conf.gpg"
    curl -sfLO "$config_url" || error "Не удалось скачать конфиг"

    read -rsp "Введите пароль для расшифровки конфигурации: " password; echo
    gpg -d --batch --passphrase "$password" jaja.conf.gpg > jaja.conf 2>/dev/null || error "Неверный пароль или повреждённый файл"
    mkdir -p /etc
    mv jaja.conf /etc/jaja.conf
    chmod 600 /etc/jaja.conf
    rm -f jaja.conf.gpg
    success "Конфигурация успешно установлена"
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
    success "Все скрипты установлены"
}

install_services() {
    echo "⚙️ Установка systemd-сервисов и таймеров..."
    local service_base="https://raw.githubusercontent.com/GoldenStiv-Fedora/jaja-agent/main/service_files"

    mkdir -p /etc/systemd/system

    for unit in fedora-auto-setup.service auto-clean-logs.service auto-clean-logs.timer; do
        curl -sfLo "/etc/systemd/system/$unit" "$service_base/$unit" || error "Ошибка скачивания $unit"
    done

    systemctl daemon-reload
    systemctl enable --now fedora-auto-setup.service
    systemctl enable --now auto-clean-logs.timer

    success "Systemd-сервисы активированы"
}

main() {
    check_root
    install_deps
    setup_config
    install_scripts
    install_services

    echo
    success "✅ Установка JAJA завершена!"
    echo "Проверь статус:"
    echo "  systemctl status fedora-auto-setup.service"
    echo "  systemctl list-timers | grep auto-clean-logs"
    echo
}

main
