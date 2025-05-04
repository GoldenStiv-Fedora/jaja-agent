// 📄 install_n8n_command.sh - автоматическая установка
#!/bin/bash

EXT_DIR="$HOME/.local/share/gnome-shell/extensions/jaja-n8n-command@jaja.gnome.shell"
REPO="https://github.com/GoldenStiv-Fedora/jaja-agent"

# Клонируем только папку с расширением n8n command
mkdir -p "$HOME/.local/share/gnome-shell/extensions/jaja-n8n-command@jaja.gnome.shell"
git clone --depth 1 "$REPO" temp_jaja_ext
cp -r temp_jaja_ext/GNOME_SHELL_N8N/extensions/jaja-n8n-command@jaja.gnome.shell "$EXT_DIR"
rm -rf temp_jaja_ext

echo "Расширение скопировано в $EXT_DIR"

# Перезагружаем GNOME Shell (для X11)
echo "Перезапуск GNOME Shell..."
killall -3 gnome-shell

# Или для Wayland просим перезайти
notify-send "JAJA Extension" "Перезайдите в сеанс GNOME или используйте 'gnome-extensions enable jaja-n8n-command@jaja.gnome.shell'"

exit 0
