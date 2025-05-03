#!/usr/bin/env bash

# === СКРИПТ: bootstrap.sh ===
# === ИНИЦИАЛИЗАЦИЯ И УСТАНОВКА JAJA С GITHUB НА ЧИСТУЮ FEDORA-СИСТЕМУ ===

set -euo pipefail

echo "[JAJA] Инициализация установки..."

# === ШАГ 1: Создание целевой директории ===
INSTALL_DIR="/home/jaja-agent"
if [[ ! -d "$INSTALL_DIR" ]]; then
  echo "[JAJA] Создаю директорию проекта: $INSTALL_DIR"
  sudo mkdir -p "$INSTALL_DIR"
  sudo chown "$(whoami)":"$(whoami)" "$INSTALL_DIR"
fi

# === ШАГ 2: Клонирование проекта с GitHub ===
if [[ ! -d "$INSTALL_DIR/.git" ]]; then
  echo "[JAJA] Клонирование репозитория..."
  git clone --branch main "https://github.com/GoldenStiv-Fedora/jaja-agent.git" "$INSTALL_DIR"
else
  echo "[JAJA] Репозиторий уже клонирован. Обновление..."
  git -C "$INSTALL_DIR" pull
fi

# === ШАГ 3: Переход в директорию проекта ===
cd "$INSTALL_DIR"

# === ШАГ 4: Расшифровка конфигурационного файла ===
echo "[JAJA] Расшифровка конфигурационного файла..."
gpg --decrypt configs/jaja.conf.gpg > "$HOME/.jaja/configs/jaja.conf"

# === ШАГ 5: Запуск install.sh ===
echo "[JAJA] Запуск основного установочного скрипта..."
bash ./install.sh

exit 0
