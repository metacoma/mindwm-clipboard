#!/bin/bash
tmpdir=$1
export tmpdir

find handlers -maxdepth 1 -type f -executable -print0 \
| xargs -0 -n1 -P"$(nproc)" -I{} sh -c '
  h="$1"; name="$(basename "$h")"
  out="$tmpdir/${name}.yaml"
  tmp="$out.$$.tmp"
  if cat /tmp/clipboard.txt | "$h" "$tmpdir" > "$tmp"; then
    mv "$tmp" "$out"
  else
    rm -f "$tmp"
    exit 1
  fi
' sh {}
