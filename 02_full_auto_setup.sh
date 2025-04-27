#!/bin/bash

####################################################################
# 02_full_auto_setup.sh — ПОЛНАЯ АВТОМАТИЧЕСКАЯ НАСТРОЙКА FEDORA    #
####################################################################

GITHUB_REPO="https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main"

# 🔄 Функция скачивания зависимых скриптов
function fetch_dependency() {
    local script_name="$1"
    curl -s -o "/tmp/$script_name" "$GITHUB_REPO/$script_name"
    chmod +x "/tmp/$script_name"
    echo "📥 Зависимость $script_name загружена."
}

# 📥 Загружаем и запускаем скрипт сбора логов
fetch_dependency "00_fetch_logs.sh"
/tmp/00_fetch_logs.sh

# 📥 Загружаем и запускаем анализатор
fetch_dependency "01_analyze_and_prepare.sh"
/tmp/01_analyze_and_prepare.sh

# 🔎 Подгружаем результаты анализа
source /tmp/system_config_detected.conf

echo "🛠️ Начинаем настройку системы на основе анализированной конфигурации..."
notify-send "Настройка начата" "Скрипт переходит к настройке Fedora!"

# 📦 Установка базовых пакетов
dnf install -y powertop tuned thermald lm_sensors irqbalance nvme-cli smartmontools audit fprintd pipewire pipewire-alsa pipewire-pulseaudio wireplumber cronie libnotify

# 🔥 Оптимизация энергопотребления
systemctl enable --now thermald.service irqbalance.service tuned.service
tuned-adm profile powersave

# 🔋 Автоматическое переключение профиля питания
cat <<'EOF' > /etc/udev/rules.d/99-powerplug.rules
SUBSYSTEM=="power_supply", ATTR{status}=="Discharging", RUN+="/usr/sbin/tuned-adm profile powersave"
SUBSYSTEM=="power_supply", ATTR{status}=="Charging", RUN+="/usr/sbin/tuned-adm profile balanced"
EOF
udevadm control --reload
udevadm trigger

# 🎵 Перезапуск PipeWire от имени пользователя
sudo -u $SUDO_USER systemctl --user restart pipewire{,-pulse}.service wireplumber.service

# 🛡️ Автоматические обновления
systemctl enable --now dnf-automatic.timer

# 📈 Настройка TCP-сетей
cat <<EOF > /etc/sysctl.d/99-network-tuning.conf
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl --system

echo "✅ Fedora настроена! Перезагрузите систему для активации всех настроек."
notify-send "Настройка Fedora завершена" "Пожалуйста, перезагрузите ноутбук."

