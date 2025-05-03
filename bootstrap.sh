#!/usr/bin/env bash

# === СКРИПТ: bootstrap.sh ===
# === ИНИЦИАЛИЗАЦИЯ СИСТЕМЫ И УСТАНОВКА ПРОЕКТА JAJA ИЗ GITHUB ===

set -euo pipefail

echo "[BOOTSTRAP] Проверка поддержки Fedora..."
if ! grep -q '^Fedora' /etc/fedora-release; then
  echo "[ОШИБКА] Поддерживается только Fedora. Обнаружено: $(cat /etc/fedora-release)"
  exit 1
fi

echo "[BOOTSTRAP] Подготовка директорий..."
sudo mkdir -p /home/jaja-agent
sudo chown "$USER":"$USER" /home/jaja-agent

echo "[BOOTSTRAP] Клонирование проекта JAJA..."
git clone https://github.com/GoldenStiv-Fedora/jaja-агент.git /home/jaja-agent

echo "[BOOTSTRAP] Запуск установочного скрипта install.sh..."
cd /home/jaja-agent
chmod +x install.sh
./install.sh
