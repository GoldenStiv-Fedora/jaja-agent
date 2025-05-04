// =========================
// 📄 УСТАНОВОЧНЫЙ СКРИПТ: install-extension.sh
// =========================
#!/bin/bash

EXT_DIR="$HOME/.local/share/gnome-shell/extensions/jaja-n8n-command@gnome-shell"
REPO="https://github.com/GoldenStiv-Fedora/jaja-agent.git"

mkdir -p "$HOME/.local/share/gnome-shell/extensions"
rm -rf "$EXT_DIR"
git clone "$REPO" "$HOME/.jaja-agent"
cp -r "$HOME/.jaja-agent/GNOME_SHELL_N8N/jaja-n8n-command" "$EXT_DIR"

# Перезапуск оболочки (для X11)
echo "Установка завершена. Перезапускаем GNOME Shell..."
echo "ALT+F2 → r → Enter для применения (если на X11)"
gnome-extensions enable jaja-n8n-command@gnome-shell

# Для Wayland просто перезайти в сессию

exit 0

// =========================
// ✅ ИТОГ
// =========================
// ➤ Расширение "JAJA N8N Command" позволяет отправлять команды напрямую из GNOME
// ➤ Поддерживаются версии GNOME 45–48
// ➤ Команды отправляются на локальный webhook n8n
// ➤ Можно подключить NLP и построить полноценного агента JAJA
