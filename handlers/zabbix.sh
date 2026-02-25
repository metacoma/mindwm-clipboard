#!/usr/bin/env bash

export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source ${SCRIPT_DIR}/zabbix/.venv/bin/activate

cmdb_keywords() {
  sed 's/\?//g' |
  awk '
    FNR==NR {
      allowed[$0]=tolower(1)
      next
    }
    {
      for (i=1; i<=NF; i++) {
        if ($i ~ /^[0-9]$/) continue
        if (allowed[tolower($i)] && !seen[tolower($i)]++) {
          print tolower($i)
        }
      }
    }
  ' ${SCRIPT_DIR}/cmdb/names.txt -
}

keywords="$(cmdb_keywords)"

test -n "${keywords}" || exit 0
python3 ${SCRIPT_DIR}/zabbix/zabbix.py ${keywords} #| tee ${tmpdir}/cmdb_output.txt
