#!/bin/bash
# ======================================================
# JAJA Agent Installer v1.0.0
# Автор: GoldenStiv-Fedora
# Дата: 2023-11-21
# ======================================================
# Назначение:
#   1. Установка системных сервисов
#   2. Настройка окружения
#   3. Активация мониторинга
# ======================================================

set -euo pipefail

# --- Конфигурация ---
VERSION="1.0.0"
CONFIG="/etc/jaja.conf"
INSTALL_DIR="/home/jaja-agent"
LOG_DIR="${INSTALL_DIR}/logs"

# --- Инициализация ---
init() {
    echo "⚙️ Инициализация установщика (v${VERSION})..."
    [[ -f "${CONFIG}" ]] || error "Конфиг не найден"
    [[ $EUID -eq 0 ]] || error "Требуются root-права"
    
    mkdir -p "${LOG_DIR}"
    chmod 750 "${LOG_DIR}"
    source "${CONFIG}"
}

# --- Установка сервисов ---
setup_services() {
    echo "🛠 Установка сервисов (v${VERSION})..."
    local services=(
        "fedora-auto-setup.service"
        "auto-clean-logs.timer"
        "jaja-auto-update.service"
    )

    for service in "${services[@]}"; do
        sudo cp "${INSTALL_DIR}/service_files/${service}" "/etc/systemd/system/"
        sudo systemctl enable "${service}"
    done
    
    sudo systemctl daemon-reload
}

# --- Настройка окружения ---
setup_environment() {
    echo "🌐 Настройка окружения (v${VERSION})..."
    
    # Оптимизация DNF
    sudo tee /etc/dnf/dnf.conf >/dev/null <<EOF
[main]
fastestmirror=true
max_parallel_downloads=10
defaultyes=true
keepcache=false
EOF

    # Настройка сети
    sudo sysctl -w net.core.default_qdisc=fq_codel
    sudo sysctl -w net.ipv4.tcp_congestion_control=bbr
}

# --- Завершение установки ---
finalize() {
    echo "✅ Установка завершена (v${VERSION})!"
    echo "Сервисы:"
    echo "  - Основной: systemctl status fedora-auto-setup"
    echo "  - Логи: journalctl -u jaja-agent"
}

# --- Главная функция ---
main() {
    init
    setup_services
    setup_environment
    finalize
}

main "$@"
