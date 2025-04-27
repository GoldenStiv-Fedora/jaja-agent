#!/bin/bash

####################################################################
# 00_fetch_logs.sh — СБОР ВСЕХ ЛОГОВ СИСТЕМЫ ПЕРЕД НАСТРОЙКОЙ       #
####################################################################

LOG_DIR="/tmp/system_logs"
mkdir -p "$LOG_DIR"

echo "📋 Сбор полной информации о системе..."

inxi -Fxxz > "$LOG_DIR/inxi_full.log" || echo "⚠️ Не удалось собрать inxi"
lshw > "$LOG_DIR/lshw_full.log" || echo "⚠️ Не удалось собрать lshw"
lscpu > "$LOG_DIR/lscpu.log"
lsblk > "$LOG_DIR/lsblk.log"
lsusb > "$LOG_DIR/lsusb.log"
lspci -vvv > "$LOG_DIR/lspci.log"
sensors > "$LOG_DIR/sensors.log"
nvme list > "$LOG_DIR/nvme_list.log" 2>/dev/null || echo "ℹ️ Нет NVMe дисков"
uname -a > "$LOG_DIR/uname.log"
cat /etc/os-release > "$LOG_DIR/os-release.log"

echo "✅ Логи собраны в папку $LOG_DIR"
notify-send "Сбор логов завершен" "Данные о системе успешно собраны."

