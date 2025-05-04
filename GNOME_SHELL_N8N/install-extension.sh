#!/bin/bash

set -e

EXT_NAME="jaja-n8n-command@jaja.gnome"
REPO_URL="https://github.com/GoldenStiv-Fedora/jaja-agent"
CLONE_DIR="/tmp/jaja-shell-extension"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$EXT_NAME"

# Клонируем репозиторий
rm -rf "$CLONE_DIR"
git clone "$REPO_URL" "$CLONE_DIR"

# Копируем расширение
mkdir -p "$EXT_DIR"
cp -r "$CLONE_DIR/GNOME_SHELL_N8N/jaja-n8n-command/"* "$EXT_DIR"

# Перезапускаем GNOME Shell (в зависимости от DE)
if command -v gnome-shell-extension-tool &> /dev/null; then
  gnome-extensions enable "$EXT_NAME"
else
  echo "Включите расширение вручную через gnome-extensions или перезапустите Shell (Alt+F2, r)"
fi

echo "JAJA N8N Command Extension установлено."
