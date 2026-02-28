#!/usr/bin/env bash

export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source ${SCRIPT_DIR}/zabbix/.venv/bin/activate

python3 ${SCRIPT_DIR}/zabbix/zabbix.py $(cat)
