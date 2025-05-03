#!/usr/bin/env bash
# ======================================================
# JAJA Agent Bootstrap Script v1.0.2
# Автор: GoldenStiv-Fedora
# Дата: 2023-11-21
# Лицензия: MIT
# ======================================================
# Изменения:
# - Добавлена проверка архитектуры
# - Оптимизирована работа с GPG
# - Улучшена обработка ошибок curl
# - Добавлен таймаут для ввода пароля
# ======================================================

set -euo pipefail

# --- Константы ---
VERSION="1.0.2"
CONFIG_URL="https://raw.githubusercontent.com/GoldenStiv-Fedora/jaja-agent/main/configs/jaja.conf.gpg"
REPO_URL="https://github.com/GoldenStiv-Fedora/jaja-agent.git"
INSTALL_DIR="/home/jaja-agent"
CONFIG_FILE="/etc/jaja.conf"
TIMEOUT=60  # Таймаут ввода пароля (секунды)

# --- Форматирование вывода ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Функции ---
error() { echo -e "${RED}[ОШИБКА]${NC} $1" >&2; exit 1; }
warning() { echo -e "${YELLOW}[ПРЕДУПРЕЖДЕНИЕ]${NC} $1"; }
success() { echo -e "${GREEN}[УСПЕХ]${NC} $1"; }

check_architecture() {
    echo "🔍 Проверка архитектуры (v${VERSION})..."
    [[ $(uname -m) == "x86_64" ]] || warning "Неподдерживаемая архитектура: $(uname -m)"
}

check_dependencies() {
    echo "🔍 Проверка зависимостей (v${VERSION})..."
    local deps=("curl" "git" "gpg" "sudo")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warning "Требуется установка: ${missing[*]}"
        sudo dnf install -y "${missing[@]}" || error "Ошибка установки"
    fi
}

download_config() {
    echo "🔐 Загрузка конфигурации (v${VERSION})..."
    local temp_file=$(mktemp)
    
    if ! curl -fsSL "${CONFIG_URL}" -o "${temp_file}"; then
        rm -f "${temp_file}"
        error "Ошибка загрузки конфига"
    fi

    read -t $TIMEOUT -rsp "Введите пароль (таймаут ${TIMEOUT}с): " password || {
        echo -e "\n\n⚠️ Таймаут ввода пароля"
        rm -f "${temp_file}"
        exit 1
    }
    echo

    if ! gpg --batch --passphrase "${password}" --decrypt "${temp_file}" 2>/dev/null | sudo tee "${CONFIG_FILE}" >/dev/null; then
        unset password
        rm -f "${temp_file}" "${CONFIG_FILE}"
        error "Ошибка расшифровки"
    fi
    
    unset password
    rm -f "${temp_file}"
    sudo chmod 600 "${CONFIG_FILE}"
    success "Конфиг сохранен в ${CONFIG_FILE}"
}

clone_repository() {
    echo "📦 Клонирование репозитория (v${VERSION})..."
    if [[ -d "${INSTALL_DIR}/.git" ]]; then
        warning "Обновление существующей копии..."
        git -C "${INSTALL_DIR}" pull || error "Ошибка обновления"
    else
        sudo mkdir -p "${INSTALL_DIR}"
        sudo chown $(id -u):$(id -g) "${INSTALL_DIR}"
        git clone --depth 1 --branch main "${REPO_URL}" "${INSTALL_DIR}" || error "Ошибка клонирования"
    fi
}

run_installer() {
    echo "🚀 Запуск инсталлятора (v${VERSION})..."
    [[ -f "${INSTALL_DIR}/install.sh" ]] || error "Файл install.sh не найден"
    
    sudo chmod +x "${INSTALL_DIR}/install.sh"
    cd "${INSTALL_DIR}" && bash ./install.sh
}

main() {
    echo -e "\n=== JAJA Bootstrap v${VERSION} ==="
    check_architecture
    check_dependencies
    download_config
    clone_repository
    run_installer
    echo -e "\n✅ Готово! Логи: ${INSTALL_DIR}/logs"
}

main "$@"
