#!/usr/bin/env bash

# === СКРИПТ: bootstrap.sh ===
# === ПЕРВОНАЧАЛЬНАЯ УСТАНОВКА: ЗАГРУЗКА И ПОДГОТОВКА ПРОЕКТА JAJA ===
# Назначение: Проверить Fedora, установить git/curl, клонировать репозиторий, запустить install.sh

set -euo pipefail

# === ПРОВЕРКА, ЧТО ЭТО FEDORA ===
echo "[BOOTSTRAP] Проверка, что система — Fedora..."
if ! grep -q '^Fedora' /etc/fedora-release; then
  echo "[ОШИБКА] Поддерживается только Fedora. Обнаружено: $(cat /etc/fedora-release)"
  exit 1
fi

# === УСТАНОВКА ОСНОВНЫХ ИНСТРУМЕНТОВ ДЛЯ КЛОНИРОВАНИЯ ===
echo "[BOOTSTRAP] Проверка наличия curl и git..."

for pkg in curl git; do
  if ! command -v "$pkg" &>/dev/null; then
    echo "[BOOTSTRAP] Установка отсутствующего пакета: $pkg"
    sudo dnf install -y "$pkg"
  fi
done

# === ПУТЬ УСТАНОВКИ ПРОЕКТА ===
INSTALL_DIR="/home/jaja-agent"
REPO_URL="https://github.com/GoldenStiv-Fedora/jaja-агент"

if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "[BOOTSTRAP] Проект уже клонирован. Обновление..."
  git -C "$INSTALL_DIR" pull
else
  echo "[BOOTSTRAP] Клонирование проекта в $INSTALL_DIR..."
  sudo rm -rf "$INSTALL_DIR"
  sudo git clone "$REPO_URL" "$INSTALL_DIR"
  sudo chown -R "$USER":"$USER" "$INSTALL_DIR"
fi

# === ПЕРЕХОД И ЗАПУСК ОСНОВНОГО УСТАНОВОЧНОГО СКРИПТА ===
echo "[BOOTSTRAP] Запуск install.sh из $INSTALL_DIR..."
bash "$INSTALL_DIR/install.sh"
