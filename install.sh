#!/usr/bin/env bash

# === СКРИПТ: install.sh ===
# === ГЛАВНЫЙ УСТАНОВОЧНЫЙ СКРИПТ ДЛЯ РАЗВЁРТЫВАНИЯ ПРОЕКТА JAJA НА FEDORA ===
# Назначение: Проверка системы, обновление, установка зависимостей, подготовка директорий, расшифровка конфигурации, запуск начальной настройки

set -euo pipefail

# === ПРОВЕРКА СОВМЕСТИМОСТИ СИСТЕМЫ ===
echo "[JAJA] Проверка поддержки Fedora..."
if ! grep -q '^Fedora' /etc/fedora-release; then
  echo "[ОШИБКА] Поддерживается только Fedora. Обнаружено: $(cat /etc/fedora-release)"
  exit 1
fi

# === ОБНОВЛЕНИЕ СИСТЕМЫ ===
echo "[JAJA] Обновление кэша DNF и всей системы..."
sudo dnf makecache --refresh -y
sudo dnf upgrade -y

# === ПРОВЕРКА И УСТАНОВКА ЗАВИСИМОСТЕЙ ===
echo "[JAJA] Проверка и установка необходимых пакетов..."
REQUIRED_PKGS=(
  git gpg wget curl coreutils gnupg2 tar unzip sed grep awk
  systemd systemd-udev util-linux cronie openssl
)
for pkg in "${REQUIRED_PKGS[@]}"; do
  if ! rpm -q "$pkg" &>/dev/null; then
    echo "[JAJA] Установка отсутствующего пакета: $pkg"
    sudo dnf install -y "$pkg"
  fi
done

# === ПОДГОТОВКА ДИРЕКТОРИЙ ДЛЯ РАБОТЫ ===
echo "[JAJA] Подготовка рабочих директорий проекта..."
mkdir -p "$HOME/.jaja/configs" \
         "$HOME/.jaja/logs" \
         "$HOME/.jaja/modules" \
         "$HOME/.jaja/tmp"

# === ДЕКРИПТОВКА КОНФИГУРАЦИИ ===
CONFIG_PATH="/home/jaja-agent/configs/jaja.conf.gpg"
if [[ -f "$CONFIG_PATH" ]]; then
  echo "[JAJA] Расшифровка конфигурационного файла..."
  gpg --decrypt "$CONFIG_PATH" > "$HOME/.jaja/configs/jaja.conf"
  source "$HOME/.jaja/configs/jaja.conf"
else
  echo "[ОШИБКА] Не найден зашифрованный конфиг: $CONFIG_PATH"
  exit 1
fi

# === ЗАПУСК ОСНОВНОГО СКРИПТА УСТАНОВКИ ===
echo "[JAJA] Запуск автоматической настройки: scripts/02_full_auto_setup.sh"
bash "/home/jaja-agent/scripts/02_full_auto_setup.sh"

echo "[JAJA] Установка завершена."
exit 0
