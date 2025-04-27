#!/bin/bash
# Проверка обновлений без утечки данных
check_updates() {
    local remote_sha=$(curl -sH "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$(basename "$0")" | jq -r '.sha')
    [[ "$remote_sha" != "$(sha256sum "$0" | awk '{print $1}')" ]] && return 1
    return 0
}
