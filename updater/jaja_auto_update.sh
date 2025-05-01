#!/bin/bash
# jaja-agent/updater/jaja_auto_update.sh
# Автообновление JAJA из GitHub (только если включено в конфиге)

set -euo pipefail

CONFIG="/etc/jaja.conf"
[[ -f "$CONFIG" ]] || { echo "❌ Конфиг не найден: $CONFIG"; exit 1; }
source "$CONFIG"

[[ "${JAJA_AUTO_UPDATE:-no}" != "yes" ]] && exit 0

GITHUB_API="https://api.github.com/repos/${GITHUB_USER}/${GITHUB_REPO}/commits/${GITHUB_BRANCH}"
LOCAL_STATE="/var/lib/jaja/last_commit"
TMP_DIR="/tmp/jaja_update"
mkdir -p "$(dirname "$LOCAL_STATE")" "$TMP_DIR"

notify() {
    [[ "${NOTIFY_ENABLED:-no}" == "yes" ]] && command -v notify-send &>/dev/null && notify-send "JAJA Update" "$1"
}

log() {
    echo "[JAJA UPDATE] $1"
}

log "🔎 Проверка обновлений из GitHub..."

REMOTE_COMMIT=$(curl -s "$GITHUB_API" | jq -r .sha | cut -c1-12)
[[ -z "$REMOTE_COMMIT" ]] && log "❌ Не удалось получить удалённый коммит" && exit 1

LOCAL_COMMIT=$(cat "$LOCAL_STATE" 2>/dev/null || echo "none")

if [[ "$REMOTE_COMMIT" == "$LOCAL_COMMIT" ]]; then
    log "✅ Актуальная версия: $REMOTE_COMMIT"
    exit 0
fi

log "⬇️ Найдено обновление! Загрузка скриптов JAJA..."

BASE_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"

FILES=(
  "scripts/00_fetch_logs.sh"
  "scripts/01_analyze_and_prepare.sh"
  "scripts/02_full_auto_setup.sh"
  "scripts/03_maintenance.sh"
  "scripts/auto_clean_logs.sh"
  "modules/setup_vpn_pptp.sh"
  "modules/huawei_audio_fix.sh"
)

for file in "${FILES[@]}"; do
    curl -sfLo "$TMP_DIR/$(basename "$file")" "$BASE_URL/$file" || log "⚠️ Не удалось обновить $file"
done

log "🛠 Обновление JAJA..."

install -Dm755 "$TMP_DIR/"* /usr/local/bin/

echo "$REMOTE_COMMIT" > "$LOCAL_STATE"
notify "JAJA обновлён до $REMOTE_COMMIT"
log "✅ Обновление завершено"
