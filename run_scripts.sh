#!/bin/bash
script_dir=$1
tmpdir=$2
export tmpdir

TMP_INPUT=$(mktemp /tmp/TMP_INPUT.XXXXXXXXXX)
export TMP_INPUT

cat > ${TMP_INPUT}

find ${script_dir} -maxdepth 1 -type f -executable -print0 \
| xargs -0 -n1 -P"$(nproc)" -I{} sh -c '
  h="$1"; name="$(basename "$h")"
  out="$tmpdir/${name}.yaml"
  tmp="$out.$$.tmp"
  if cat ${TMP_INPUT} | "$h" "$tmpdir" > "$tmp"; then
    mv "$tmp" "$out"
  else
    rm -f "$tmp"
    exit 1
  fi
' sh {}
