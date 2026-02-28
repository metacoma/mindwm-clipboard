#!/usr/bin/env bash

export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source ${SCRIPT_DIR}/.venv/bin/activate
. ${SCRIPT_DIR}/../.env
export ZABBIX_URL=${ZABBIX_URL}/api_jsonrpc.php

if [[ "$2" =~ ^[0-9]+$ ]]; then
    python3 /home/bebebeka/spaces/mindwm/clipboard/bin/zabbix_download_image.py --cookie-file /tmp/zabbix_cookie --width=600 --height=320 --graphid "$2" "$1" "" | display -
else
    python3 /home/bebebeka/spaces/mindwm/clipboard/bin/zabbix_download_image.py --cookie-file /tmp/zabbix_cookie --width=600 --height=320 "$1" "$2" | display -
fi
