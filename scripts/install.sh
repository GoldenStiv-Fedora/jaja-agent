#!/bin/bash

# Установочный скрипт Fedora Auto-Setup (версия 5.0)

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Функции вывода
error() { echo -e "${RED}[ОШИБКА]${NC} $1" >&2; exit 1; }
warning() { echo -e "${YELLOW}[ПРЕДУПРЕЖДЕНИЕ]${NC} $1"; }
success() { echo -e "${GREEN}[УСПЕХ]${NC} $1"; }

# Проверка root-прав
check_root() {
    [[ $EUID -ne 0 ]] && error "Скрипт должен запускаться от root. Используйте sudo."
}

# Проверка и установка зависимостей
install_deps() {
    local deps=("curl" "gpg" "jq" "libnotify" "systemd" "dnf5")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            warning "Установка $dep..."
            dnf install -y "$dep" || error "Не удалось установить $dep"
        fi
    done
}

# Загрузка и расшифровка конфига
setup_config() {
    echo "🔐 Скачивание зашифрованного конфига..."
    local config_url="https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main/configs/fedora-setup.conf.gpg"
    curl -sLO "$config_url" || error "Не удалось скачать конфиг"

    read -rsp "Введите пароль для расшифровки конфига: " password
    echo
    gpg -d --batch --passphrase "$password" fedora-setup.conf.gpg > fedora-setup.conf 2>/dev/null || error "Неверный пароль или повреждённый файл"

    mkdir -p /etc
    mv fedora-setup.conf /etc/fedora-setup.conf
    chmod 600 /etc/fedora-setup.conf
    rm -f fedora-setup.conf.gpg
    success "Конфиг установлен и защищён"
}

# Установка основных скриптов
install_scripts() {
    echo "⬇️ Скачивание и установка скриптов..."
    local repo_base="https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main/scripts"
    local scripts=("00_fetch_logs.sh" "01_analyze_and_prepare.sh" "02_full_auto_setup.sh" "03_maintenance.sh" "auto_clean_logs.sh")
    
    mkdir -p /usr/local/bin
    for script in "${scripts[@]}"; do
        curl -sLo "/usr/local/bin/$script" "$repo_base/$script" || error "Ошибка скачивания $script"
        chmod +x "/usr/local/bin/$script"
    done
    success "Все скрипты установлены"
}

# Установка systemd-юнитов
install_services() {
    echo "⚙️ Установка systemd сервисов и таймеров..."
    local service_repo="https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main/service_files"

    mkdir -p /etc/systemd/system

    curl -sLo /etc/systemd/system/fedora-auto-setup.service "$service_repo/fedora-auto-setup.service" || error "Ошибка скачивания fedora-auto-setup.service"
    curl -sLo /etc/systemd/system/auto-clean-logs.service "$service_repo/auto-clean-logs.service" || error "Ошибка скачивания auto-clean-logs.service"
    curl -sLo /etc/systemd/system/auto-clean-logs.timer "$service_repo/auto-clean-logs.timer" || error "Ошибка скачивания auto-clean-logs.timer"

    systemctl daemon-reload
    systemctl enable --now fedora-auto-setup.service
    systemctl enable --now auto-clean-logs.timer

    success "Сервисы и таймеры активированы"
}

# Главная функция
main() {
    check_root
    install_deps
    setup_config
    install_scripts
    install_services

    echo
    success "✅ Установка Fedora Setup завершена!"
    echo "Проверить службу можно командой:"
    echo "  systemctl status fedora-auto-setup.service"
    echo
    echo "Проверить таймер очистки логов:"
    echo "  systemctl list-timers | grep auto-clean-logs"
}

main
