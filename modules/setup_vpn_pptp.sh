#!/bin/bash
# jaja-agent/modules/setup_vpn_pptp.sh
# Установка поддержки PPTP VPN в Fedora

set -euo pipefail

CONFIG="/etc/jaja.conf"
[[ -f "$CONFIG" ]] || { echo "❌ Конфиг не найден: $CONFIG"; exit 1; }
source "$CONFIG"

[[ "${ENABLE_VPN_SETUP:-no}" != "yes" ]] && exit 0

notify() {
    [[ "${NOTIFY_ENABLED:-no}" == "yes" ]] && command -v notify-send &>/dev/null && notify-send "JAJA VPN" "$1"
}

log() {
    echo -e "[VPN] $1"
}

log "📦 Установка необходимых пакетов..."
dnf install -y \
    NetworkManager-pptp \
    NetworkManager-pptp-gnome \
    pptp \
    ppp \
    policycoreutils-python-utils || log "⚠️ Некоторые пакеты уже установлены"

log "🛡 Разрешение протокола GRE (47)..."
firewall-cmd --permanent --add-protocol=gre || true
firewall-cmd --reload || true

log "🔐 Настройка SELinux для логов pppd..."
mkdir -p /var/log/vpn
touch /var/log/vpn/ppp.log
chown root:root /var/log/vpn/ppp.log
chmod 644 /var/log/vpn/ppp.log
semanage fcontext -a -t pppd_log_t "/var/log/vpn/ppp.log"
restorecon -v /var/log/vpn/ppp.log

log "🔄 Перезапуск NetworkManager..."
systemctl restart NetworkManager || true

notify "Поддержка VPN (PPTP) установлена"
log "✅ VPN готов. Используйте GUI или nmcli для подключения."
