#!/bin/bash
set -e

echo "Installing Huawei Audio Jack Monitor..."

dnf install -y alsa-utils alsa-tools hda-verb

install -Dm755 drivers/huawei-audio-fix/huawei-soundcard-headphones-monitor.sh /usr/local/bin/huawei-soundcard-headphones-monitor.sh
install -Dm644 drivers/huawei-audio-fix/huawei-soundcard-headphones-monitor.service /etc/systemd/system/huawei-soundcard-headphones-monitor.service

systemctl daemon-reload
systemctl enable --now huawei-soundcard-headphones-monitor.service

echo "✅ Huawei Audio Jack Monitor successfully installed and running."
