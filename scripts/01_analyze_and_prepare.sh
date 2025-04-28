#!/bin/bash
# 01_analyze_and_prepare.sh — Анализ CPU и подготовка настроек

LOG_DIR="/tmp/system_logs"
CPU_VENDOR=$(grep -m1 "vendor_id" "$LOG_DIR/lscpu.log" | cut -d: -f2 | tr -d '[:space:]')
echo "cpu_vendor=$CPU_VENDOR" > /tmp/system_config_detected.conf
