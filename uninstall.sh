#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Пожалуйста, запустите скрипт с правами root (sudo ./uninstall.sh)"
  exit 1
fi

echo "🗑️ Начинаем удаление SSH Telegram Guard..."

# 1. Очистка конфигурации PAM
PAM_SSHD="/etc/pam.d/sshd"
if grep -Fq "/etc/ssh/login_notify.sh" "$PAM_SSHD"; then
    # Создается резервная копия /etc/pam.d/sshd.bak на случай сбоя
    sed -i.bak '\|/etc/ssh/login_notify.sh|d' "$PAM_SSHD"
    echo "✅ Правило удалено из $PAM_SSHD (создан бэкап sshd.bak)"
else
    echo "ℹ️ Правило в $PAM_SSHD не найдено"
fi

# 2. Удаление скрипта и файла с токенами
rm -f /etc/ssh/login_notify.sh
rm -f /etc/ssh/tg_guard.env
echo "✅ Скрипт уведомлений и файл с токенами удалены"

# 3. Удаление конфигураций Fail2ban
rm -f /etc/fail2ban/action.d/telegram.conf
rm -f /etc/fail2ban/jail.d/ssh-telegram.local
echo "✅ Конфигурации Telegram удалены из Fail2ban"

# 4. Перезапуск Fail2ban для применения стандартных настроек
if systemctl is-active --quiet fail2ban; then
    echo "🔄 Перезапуск Fail2ban..."
    systemctl restart fail2ban
fi

echo "🎉 Удаление успешно завершено! Все настройки возвращены в исходное состояние."
