#!/bin/bash

# Проверяем, существует ли файл
if [ -f "/etc/jaja.conf" ]; then
    echo "Содержимое /etc/jaja.conf:"
    echo "--------------------------"
    cat /etc/jaja.conf
    echo "--------------------------"
else
    echo "Ошибка: файл /etc/jaja.conf не найден!" >&2
    exit 1
fi
