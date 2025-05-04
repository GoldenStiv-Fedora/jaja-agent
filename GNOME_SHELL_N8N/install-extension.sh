#!/bin/bash

# Скрипт автоматической установки GNOME Shell расширения JAJA

set -e

EXTENSION_ID="jaja-n8n-command@jaja-agent"
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_ID"
REPO="https://github.com/GoldenStiv-Fedora/jaja-agent"

mkdir -p "$EXTENSION_DIR"
cd "$EXTENSION_DIR"

# Клонируем только нужную папку
git init
git remote add origin "$REPO"
git config core.sparseCheckout true
echo "GNOME_SHELL_N8N/*" > .git/info/sparse-checkout
git pull origin main

# Копируем содержимое нужной папки в корень расширения
mv GNOME_SHELL_N8N/* ./
rm -rf GNOME_SHELL_N8N

# Перезапускаем GNOME Shell (для Wayland)
echo "Установлено в $EXTENSION_DIR"
echo "Перезапускаем GNOME Shell..."

if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  gnome-extensions enable "$EXTENSION_ID"
  echo "Расширение активировано. Перезапустите GNOME Shell вручную или перезайдите."\else
  gnome-shell-extension-tool -e "$EXTENSION_ID"
  echo "Расширение активировано. Нажмите ALT+F2, введите 'r' и нажмите Enter."
fi
