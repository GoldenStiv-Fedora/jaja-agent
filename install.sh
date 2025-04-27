#!/bin/bash

# Загрузка зашифрованного конфига
curl -sO https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main/fedora-setup.conf.gpg

# Запрос пароля и расшифровка
read -sp "Введите пароль для конфига: " password
if ! gpg -d --batch --passphrase "$password" fedora-setup.conf.gpg > fedora-setup.conf; then
    echo "❌ Неверный пароль!"
    exit 1
fi

# Переносим конфиг в /etc
sudo mv fedora-setup.conf /etc/
sudo chmod 600 /etc/fedora-setup.conf

# Установка зависимостей
sudo dnf install -y jq curl libnotify

# Загрузка скриптов
scripts=(00_fetch_logs.sh 01_analyze_and_prepare.sh 02_full_auto_setup.sh)
for script in "${scripts[@]}"; do
    sudo curl -o "/usr/local/bin/$script" \
        "https://raw.githubusercontent.com/GoldenStiv-Fedora/fedora-setup/main/$script"
    sudo chmod +x "/usr/local/bin/$script"
done

# Запуск
sudo /usr/local/bin/02_full_auto_setup.sh
