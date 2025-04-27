#!/bin/bash

####################################################################
# 01_analyze_and_prepare.sh — АНАЛИЗ И ПОДГОТОВКА НАСТРОЕК          #
####################################################################

LOG_DIR="/tmp/system_logs"

echo "🔎 Анализируем собранные логи..."

CPU_VENDOR=$(grep 'Vendor ID:' "$LOG_DIR/lscpu.log" | awk '{print $3}')
GPU_VENDOR=$(grep -i 'VGA' "$LOG_DIR/lspci.log" | grep -oE 'Intel|NVIDIA|AMD')
HAS_NVME=$(grep -i 'nvme' "$LOG_DIR/lsblk.log" || true)

# Сохраняем параметры в файл настроек
CONFIG_FILE="/tmp/system_config_detected.conf"
echo "cpu_vendor=$CPU_VENDOR" > "$CONFIG_FILE"
echo "gpu_vendor=$GPU_VENDOR" >> "$CONFIG_FILE"
echo "has_nvme=$([[ -n \"$HAS_NVME\" ]] && echo yes || echo no)" >> "$CONFIG_FILE"

echo "📋 Конфигурация сохранена в $CONFIG_FILE"
notify-send "Анализ завершен" "Конфигурация системы готова для оптимизации."

