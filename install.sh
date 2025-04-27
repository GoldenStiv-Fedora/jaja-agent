#!/bin/bash

# Установочный скрипт Fedora Auto-Setup
# Версия 3.0 (стабильная)

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
    if [[ $EUID -ne 0 ]]; then
        error "Этот скрипт должен запускаться с root-правами. Используйте sudo."
    fi
}

# Установка зависимостей
install_deps() {
    local deps=("curl" "gpg" "jq" "libnotify" "systemd")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            warning "Устанавливаем $dep..."
            dnf install -y "$dep" || error "Не удалось установить $dep"
        fi
    done
}

# Загрузка и расшифровка конфига
setup_config() {
    local config_url="https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main/fedora-setup.conf.gpg"
    
    echo -n "Загружаем конфиг... "
    if ! curl -sLO "$config_url"; then
        error "Ошибка загрузки конфига"
    fi
    
    read -rsp "Введите пароль для расшифровки: " password
    echo
    if ! gpg -d --batch --passphrase "$password" fedora-setup.conf.gpg > fedora-setup.conf 2>/dev/null; then
        error "Неверный пароль или повреждённый файл"
    fi
    
    mkdir -p /etc
    mv fedora-setup.conf /etc/
    chmod 600 /etc/fedora-setup.conf
    rm -f fedora-setup.conf.gpg
    success "Конфиг установлен"
}

# Установка основных скриптов
install_scripts() {
    local scripts=("00_fetch_logs.sh" "01_analyze_and_prepare.sh" "02_full_auto_setup.sh")
    local repo_url="https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main"
    
    mkdir -p /usr/local/bin
    for script in "${scripts[@]}"; do
        echo -n "Устанавливаем $script... "
        if curl -sLo "/usr/local/bin/$script" "$repo_url/$script"; then
            chmod +x "/usr/local/bin/$script"
            success "OK"
        else
            error "Ошибка загрузки"
        fi
    done
}

# Настройка systemd службы
setup_service() {
    cat > /etc/systemd/system/fedora-auto-setup.service <<'EOF'
[Unit]
Description=Fedora Auto-Setup Service
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=5

[Service]
Type=simple
ExecStart=/usr/local/bin/02_full_auto_setup.sh --daemon
Restart=on-failure
RestartSec=30s
EnvironmentFile=/etc/fedora-setup.conf
TimeoutStartSec=300
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now fedora-auto-setup.service
}

# Главная функция
main() {
    check_root
    install_deps
    setup_config
    install_scripts
    setup_service
    
    success "Установка завершена!"
    echo "Служба успешно запущена. Проверить статус:"
    echo "  systemctl status fedora-auto-setup.service"
}

main
