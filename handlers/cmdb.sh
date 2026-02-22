#!/usr/bin/env bash

export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source ${SCRIPT_DIR}/cmdb/.venv/bin/activate

cmdb_keywords() {
  awk '
    FNR==NR {
      allowed[$0]=1
      next
    }
    {
      for (i=1; i<=NF; i++) {
        if ($i ~ /^[0-9]$/) continue
        if (allowed[$i] && !seen[$i]++) {
          print $i
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
