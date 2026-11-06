#!/bin/bash

CONFIG_FILE="/etc/ssh/tg_guard.env"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    exit 0
fi

if [ "$PAM_TYPE" = "open_session" ]; then
    USER_NAME="$PAM_USER"
    USER_IP="${PAM_RHOST:-Неизвестно}"
    SERVER_HOST="$(hostname -f)"
    SERVER_IP="$(hostname -I | awk '{print $1}')"
    DATE_NOW="$(date "+%Y-%m-%d %H:%M:%S")"

    MESSAGE="<b>⚠️ Вход по SSH на сервер!</b>%0A"
    MESSAGE+="<b>Сервер:</b> $SERVER_HOST ($SERVER_IP)%0A"
    MESSAGE+="<b>Пользователь:</b> <code>$USER_NAME</code>%0A"
    MESSAGE+="<b>IP-адрес:</b> <code>$USER_IP</code>%0A"
    MESSAGE+="<b>Время:</b> $DATE_NOW"

    curl -s -o /dev/null -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TG_CHAT_ID}" \
        -d "text=${MESSAGE}" \
        -d "parse_mode=HTML" &
fi
