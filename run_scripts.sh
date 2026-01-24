#!/bin/bash
script_dir=$1
tmpdir=$2
export tmpdir

tmp_input=$(mktemp /tmp/tmp_input.XXXXXXXXXX)
export tmp_input

cat > ${tmp_input}

find ${script_dir} -maxdepth 1 -type f -executable -print0 \
| xargs -0 -n1 -P"$(nproc)" -I{} sh -c '
  h="$1"; name="$(basename "$h")"
  out="$tmpdir/${name}.yaml"
  tmp="$out.$$.tmp"
  if cat ${tmp_input} | "$h" "$tmpdir" > "$tmp"; then
    mv "$tmp" "$out"
  else
    rm -f "$tmp"
    exit 1
  fi
' sh {}
