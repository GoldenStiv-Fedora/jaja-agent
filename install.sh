#!/bin/bash
# install.sh — Установка всех компонентов проекта Fedora Setup

set -e

REPO_URL="https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main"

# Установка зависимостей
dnf install -y curl jq gpg libnotify systemd cronie

# Скачивание и установка скриптов
mkdir -p /usr/local/bin
curl -sLo /usr/local/bin/00_fetch_logs.sh "$REPO_URL/scripts/00_fetch_logs.sh"
curl -sLo /usr/local/bin/01_analyze_and_prepare.sh "$REPO_URL/scripts/01_analyze_and_prepare.sh"
curl -sLo /usr/local/bin/02_full_auto_setup.sh "$REPO_URL/scripts/02_full_auto_setup.sh"
chmod +x /usr/local/bin/*.sh

# Скачивание зашифрованного конфига
curl -sLo /etc/fedora-setup.conf.gpg "$REPO_URL/configs/fedora-setup.conf.gpg"
gpg --batch --passphrase "Stiv123123123*" --decrypt /etc/fedora-setup.conf.gpg > /etc/fedora-setup.conf

# Установка службы systemd
curl -sLo /etc/systemd/system/fedora-auto-setup.service "$REPO_URL/service_files/fedora-auto-setup.service"
systemctl daemon-reload
systemctl enable --now fedora-auto-setup.service
