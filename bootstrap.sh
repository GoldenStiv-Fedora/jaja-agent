#!/usr/bin/env bash
# ======================================================
# JAJA Agent Bootstrap Script v1.0.1
# Автор: GoldenStiv-Fedora
# Дата: 2023-11-20
# Лицензия: MIT
# Репозиторий: https://github.com/GoldenStiv-Fedora/jaja-agent
# ======================================================
# Назначение:
#   Первичная инициализация системы для установки JAJA Agent:
#   1. Проверка зависимостей (curl, git, gpg, sudo)
#   2. Загрузка и расшифровка конфигурации
#   3. Клонирование репозитория
#   4. Запуск основного инсталлятора
# Особенности:
#   - Полная автоматизация установки
#   - Защищенное хранение конфигов (GPG-шифрование)
#   - Контроль версий и целостности
# ======================================================

set -euo pipefail

# --- Константы ---
VERSION="1.0.1"
CONFIG_URL="https://raw.githubusercontent.com/GoldenStiv-Fedora/jaja-agent/main/configs/jaja.conf.gpg"
REPO_URL="https://github.com/GoldenStiv-Fedora/jaja-agent.git"
INSTALL_DIR="/home/jaja-agent"
CONFIG_FILE="/etc/jaja.conf"

# --- Форматирование вывода ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Функции логирования ---
error() {
    echo -e "${RED}[ОШИБКА]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[ПРЕДУПРЕЖДЕНИЕ]${NC} $1"
}

success() {
    echo -e "${GREEN}[УСПЕХ]${NC} $1"
}

# --- Проверка зависимостей ---
check_dependencies() {
    echo "🔍 Проверка системных зависимостей (v${VERSION})..."
    local deps=("curl" "git" "gpg" "sudo")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warning "Отсутствующие зависимости: ${missing[*]}"
        echo "🔄 Установка недостающих пакетов..."
        sudo dnf install -y "${missing[@]}" || error "Не удалось установить зависимости"
    fi
    success "Системные зависимости удовлетворены"
}

# --- Загрузка конфигурации ---
download_config() {
    echo "🔐 Загрузка конфигурации (v${VERSION})..."
    echo -n "Введите пароль для расшифровки: "
    read -rs password
    echo

    if ! sudo bash -c "curl -sL '${CONFIG_URL}' | gpg --batch --passphrase '${password}' --decrypt -o '${CONFIG_FILE}' 2>/dev/null"; then
        unset password
        error "Ошибка расшифровки конфига"
    fi
    unset password

    sudo chmod 600 "${CONFIG_FILE}"
    sudo chown root:root "${CONFIG_FILE}"
    success "Конфигурация сохранена в ${CONFIG_FILE}"
}

# --- Клонирование репозитория ---
clone_repository() {
    echo "📦 Клонирование репозитория (v${VERSION})..."
    if [[ -d "${INSTALL_DIR}/.git" ]]; then
        warning "Обнаружена существующая копия проекта"
        return
    fi

    sudo mkdir -p "${INSTALL_DIR}"
    sudo chown "$(whoami):$(whoami)" "${INSTALL_DIR}"
    git clone --branch main "${REPO_URL}" "${INSTALL_DIR}" || error "Ошибка клонирования"
    success "Проект склонирован в ${INSTALL_DIR}"
}

# --- Запуск инсталлятора ---
run_installer() {
    echo "🚀 Запуск инсталлятора (v${VERSION})..."
    cd "${INSTALL_DIR}" || error "Не удалось перейти в ${INSTALL_DIR}"

    # Временное повышение прав для чтения конфига
    sudo chmod 644 "${CONFIG_FILE}"
    bash ./install.sh || error "Ошибка выполнения install.sh"
    sudo chmod 600 "${CONFIG_FILE}"
}

# --- Главная функция ---
main() {
    echo -e "\n=== JAJA Agent Bootstrap v${VERSION} ==="
    check_dependencies
    download_config
    clone_repository
    run_installer
    echo -e "\n✅ Установка завершена успешно!"
    echo "Директория проекта: ${INSTALL_DIR}"
    echo "Конфигурация: ${CONFIG_FILE}"
}

main "$@"
