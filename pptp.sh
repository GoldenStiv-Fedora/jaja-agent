#!/bin/bash

set -e

### ПОЛНЫЙ СКРИПТ УСТАНОВКИ И НАСТРОЙКИ VPN (PPTP) для Fedora ###

### ПОДГОТОВКА ###
echo "\n🔧 Устанавливаю необходимые пакеты..."
sudo dnf install -y \
  NetworkManager-pptp \
  NetworkManager-pptp-gnome \
  pptp \
  ppp \
  policycoreutils-python-utils || echo "-- Некоторые пакеты уже установлены"

### РАЗРЕШЕНИЕ GRE (Generic Routing Encapsulation) ###
echo "\n🛡️ Разрешаю протокол GRE (47)..."
sudo firewall-cmd --permanent --add-protocol=gre || true
sudo firewall-cmd --reload

### SELinux: Позволяем pppd записывать логи ###
echo "\n🔒 Настраиваю SELinux для /var/log/vpn/ppp.log..."
sudo mkdir -p /var/log/vpn
sudo touch /var/log/vpn/ppp.log
sudo chown root:root /var/log/vpn/ppp.log
sudo chmod 644 /var/log/vpn/ppp.log
sudo semanage fcontext -a -t pppd_log_t "/var/log/vpn/ppp.log"
sudo restorecon -v /var/log/vpn/ppp.log

### РЕСТАРТ СЕТЕВОГО МЕНЕДЖЕРА ###
echo "\n🔄 Перезапускаю NetworkManager..."
sudo systemctl restart NetworkManager

### ГОТОВО ###
echo "\n✅ Готово! VPN PPTP поддержка установлена и настроена. \n🔧 Теперь можно настроить подключение VPN через NetworkManager GUI или nmcli."

