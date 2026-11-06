#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Пожалуйста, запустите скрипт с правами root (sudo ./install.sh)"
  exit 1
fi

if [ ! -f ".env" ]; then
  echo "❌ Файл .env не найден! Скопируйте .env.example в .env и заполните данные."
  exit 1
fi

echo "📦 Проверка и установка зависимостей (curl, fail2ban)..."
apt-get update -qq
apt-get install -y curl fail2ban -qq

echo "🔐 Настройка конфигурационного файла с токенами..."
cp .env /etc/ssh/tg_guard.env
chmod 600 /etc/ssh/tg_guard.env
chown root:root /etc/ssh/tg_guard.env

echo "📜 Установка PAM-скрипта для отслеживания входов..."
cp scripts/login_notify.sh /etc/ssh/login_notify.sh
chmod +x /etc/ssh/login_notify.sh

PAM_SSHD="/etc/pam.d/sshd"
PAM_LINE="session optional pam_exec.so /etc/ssh/login_notify.sh"
if ! grep -Fq "/etc/ssh/login_notify.sh" "$PAM_SSHD"; then
    echo "$PAM_LINE" >> "$PAM_SSHD"
    echo "✅ Правило успешно добавлено в $PAM_SSHD"
else
    echo "ℹ️ Правило в $PAM_SSHD уже существует"
fi

echo "🛡️ Настройка Fail2ban..."
cp fail2ban/telegram.conf /etc/fail2ban/action.d/telegram.conf
cp fail2ban/jail.local /etc/fail2ban/jail.d/ssh-telegram.local

echo "🔄 Перезапуск Fail2ban..."
systemctl enable fail2ban
systemctl restart fail2ban

echo "🎉 Установка успешно завершена! Мониторинг активен."
