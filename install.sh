#!/bin/bash

# Установочный скрипт Fedora Auto-Setup
# Безопасная версия (без паролей в коде)

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Функции для вывода
error() { echo -e "${RED}[ОШИБКА]${NC} $1" >&2; exit 1; }
success() { echo -e "${GREEN}[УСПЕХ]${NC} $1"; }

check_dependencies() {
    local deps=("curl" "gpg" "jq")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            echo "Устанавливаем $dep..."
            sudo dnf install -y "$dep" || error "Не удалось установить $dep"
        fi
    done
}

decrypt_config() {
    # Запрашиваем пароль только если файл существует
    if [[ -f "fedora-setup.conf.gpg" ]]; then
        read -rsp "Введите пароль для расшифровки: " password
        echo
        if ! gpg -d --batch --passphrase "$password" fedora-setup.conf.gpg > fedora-setup.conf; then
            error "Неверный пароль или повреждённый файл"
        fi
        return 0
    fi
    return 1
}

main_install() {
    echo "=== Установка Fedora Auto-Setup ==="
    
    # 1. Скачиваем зашифрованный конфиг
    echo "Загружаем конфигурацию..."
    if ! curl -sO "https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main/fedora-setup.conf.gpg"; then
        error "Не удалось загрузить конфиг"
    fi

    # 2. Интерактивная расшифровка
    if ! decrypt_config; then
        error "Не удалось расшифровать конфиг"
    fi

    # 3. Установка конфига
    sudo mkdir -p /etc
    sudo mv fedora-setup.conf /etc/
    sudo chmod 600 /etc/fedora-setup.conf
    rm -f fedora-setup.conf.gpg

    # 4. Установка скриптов
    declare -a scripts=("00_fetch_logs.sh" "01_analyze_and_prepare.sh" "02_full_auto_setup.sh")
    for script in "${scripts[@]}"; do
        echo "Устанавливаем $script..."
        sudo curl -o "/usr/local/bin/$script" \
            "https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main/$script" || \
            error "Не удалось загрузить $script"
        sudo chmod +x "/usr/local/bin/$script"
    done

    # 5. Настройка службы
    echo "Настраиваем службу..."
    sudo tee /etc/systemd/system/fedora-auto-setup.service >/dev/null <<EOF
[Unit]
Description=Fedora Auto-Setup Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/02_full_auto_setup.sh
Restart=on-failure
EnvironmentFile=/etc/fedora-setup.conf

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable --now fedora-auto-setup.service

    success "Установка завершена!"
    echo -e "\nДля немедленной настройки выполните:"
    echo "sudo /usr/local/bin/02_full_auto_setup.sh"
}

# Главный процесс
check_dependencies
main_install

# Уведомление (если доступно)
if command -v notify-send &>/dev/null; then
    notify-send "Fedora Auto-Setup" "Установка завершена успешно!"
fi
