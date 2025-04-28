#!/bin/bash

set -e

echo "🚀 Установка минимального звукового патча Huawei..."

# Установка зависимостей
sudo dnf install -y alsa-tools alsa-utils hda-verb

# Копирование файлов
sudo cp huawei-soundcard-headphones-monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/huawei-soundcard-headphones-monitor.sh

sudo cp huawei-soundcard-headphones-monitor.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/huawei-soundcard-headphones-monitor.service

# Перезагрузка systemd и запуск службы
sudo systemctl daemon-reload
sudo systemctl enable --now huawei-soundcard-headphones-monitor.service

echo "✅ Установка завершена успешно!"
systemctl status huawei-soundcard-headphones-monitor.service

