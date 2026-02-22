#!/usr/bin/env bash

export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source ${SCRIPT_DIR}/cmdb/.venv/bin/activate

cmdb_keywords() {
  local keywords=""
  local token

  # read whole stdin (works even without trailing newline)
  local input
  input="$(cat)"

  # remove []()! -> split into words -> check each in names.txt
  while IFS= read -r token || [[ -n "$token" ]]; do
    [[ -z "$token" ]] && continue
    if grep -iqx -- "$token" "${SCRIPT_DIR}/cmdb/names.txt"; then
      keywords+="${keywords:+ }$token"
    fi
  done < <(printf '%s' "$input" | tr -d '[]()!' | tr -s '[:space:]' '\n')

  printf '%s\n' "$keywords"
}

cmdb_keywords2() {
  cat \
  | tr -d '[]()!' \
  | tr -s '[:space:]' '\n' \
  | grep -vE '^[0-9]$' \
  | grep -Fixf "${SCRIPT_DIR}/cmdb/names.txt" \
  | sort \
  | uniq -u \
  | xargs
}

cmdb_keywords3() {
  awk -v names="${SCRIPT_DIR}/cmdb/names.txt" '
    BEGIN {
      IGNORECASE = 1
      while ((getline line < names) > 0) {
        gsub(/^[ \t\r\n]+|[ \t\r\n]+$/, "", line)
        if (line != "") allow[line] = 1
      }
      close(names)
    }

    {
      gsub(/[\[\]\(\)!]/, " ")
      for (i = 1; i <= NF; i++) {
        w = $i
        if (w == "") continue
        if (w ~ /^[0-9]$/) continue
        if (allow[w]) cnt[w]++
      }
    }

    END {
      out = ""
      for (w in cnt) {
        if (cnt[w] == 1) out = out (out ? " " : "") w
      }
      print out
    }
  '
}

keywords="$(cmdb_keywords)"

while IFS= read -r word; do
    if grep -iq -- "$word" "${SCRIPT_DIR}/cmdb/names.txt"; then
      keywords+=" $word"
    fi
done
test -n "${keywords}" || exit 0
python3 ${SCRIPT_DIR}/cmdb/cmdb.py ${keywords} | tee ${tmpdir}/cmdb_output.txt

IPS=$(yq '.. | scalars' ${tmpdir}/cmdb_output.txt | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u)
#echo $IPS > ${tmpdir}/ips.txt
printf "%s\n" "$IPS" \
  | xargs -P 8 -I{} bash -c "
      ip="{}"
      echo {} | ${SCRIPT_DIR}/ip4.sh ${tmpdir} 'Ip {}' > ${tmpdir}/{}.yaml
    "
