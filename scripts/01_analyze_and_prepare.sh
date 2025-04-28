#!/bin/bash

LOG_DIR="/tmp/system_logs"
[[ ! -d "$LOG_DIR" ]] && { echo "❌ Логи не найдены!"; exit 1; }

CPU_VENDOR=$(grep -m1 "vendor_id" "$LOG_DIR/lscpu.log" | cut -d: -f2 | tr -d '[:space:]')
echo "cpu_vendor=$CPU_VENDOR" > /tmp/system_config_detected.conf
