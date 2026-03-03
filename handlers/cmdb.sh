#!/usr/bin/env bash

export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
#source ${SCRIPT_DIR}/cmdb/.venv/bin/activate

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
python3 ${SCRIPT_DIR}/cmdb/cmdb.py ${keywords} | tee ${tmpdir}/cmdb_output.txt

IPS=$(yq '.. | scalars' ${tmpdir}/cmdb_output.txt | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)
printf "%s\n" "$IPS" \
  | xargs -P 8 -I{} bash -c "
      ip="{}"
      echo {} | ${SCRIPT_DIR}/ip4.sh ${tmpdir} 'Ip {}' > ${tmpdir}/{}.yaml
    "
HOST_NAMES=$(yq -r '
  ..
  | objects
  | ( .hosts? // .["cmdb.host"]? )
  | arrays
  | .[]
  | .name? // empty
' ${tmpdir}/cmdb_output.txt
)

echo ${HOST_NAMES} | bash ${SCRIPT_DIR}/zabbix.sh ${tmpdir} > ${tmpdir}/monitoring.yaml

SITES=$(yq -r '.monitoring.hosts[]?
       | .nginx?
       | .site[]?
       | .name? // empty' ${tmpdir}/monitoring.yaml)

echo ${SITES} > ${tmpdir}/sites.txt
printf '%s\n' $SITES | xargs -P0 -I{} sh -c "
  bash ${SCRIPT_DIR}/find_upstream.sh {} > ${tmpdir}/upstream_{}.yaml
"
