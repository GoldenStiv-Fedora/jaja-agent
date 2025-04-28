#!/bin/bash
# auto_clean_logs.sh — Автоудаление логов старше 21 дня на GitHub

CONFIG_FILE="/etc/fedora-setup.conf"
[ -f "$CONFIG_FILE" ] || { echo "Конфиг не найден!"; exit 1; }
source "$CONFIG_FILE"

REPO_API="https://api.github.com/repos/$GITHUB_USER/$GITHUB_LOG_REPO/contents/logs"

# Получаем список файлов логов
files=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$REPO_API" | jq -r '.[] | "\(.path) \(.sha) \(.name)"')

CURRENT_DATE=$(date +%s)

while IFS= read -r line; do
    FILE=$(echo "$line" | awk '{print $1}')
    SHA=$(echo "$line" | awk '{print $2}')
    NAME=$(echo "$line" | awk '{print $3}')
    
    # Извлекаем дату из имени файла
    FILE_DATE=$(echo "$NAME" | grep -oP '\d{8}')
    if [[ -n "$FILE_DATE" ]]; then
        FILE_TIMESTAMP=$(date -d "${FILE_DATE:0:4}-${FILE_DATE:4:2}-${FILE_DATE:6:2}" +%s)
        AGE_DAYS=$(( (CURRENT_DATE - FILE_TIMESTAMP) / 86400 ))
        
        if (( AGE_DAYS > MAX_LOG_AGE )); then
            echo "Удаление старого лога ($AGE_DAYS дней): $FILE"
            curl -s -X DELETE -H "Authorization: token $GITHUB_TOKEN" \
                -d "{\"message\":\"Удаление старого лога $NAME\", \"sha\":\"$SHA\"}" \
                "$REPO_API/$FILE"
        fi
    fi
done <<< "$files"
