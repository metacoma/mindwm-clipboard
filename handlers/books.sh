#!/usr/bin/env bash


SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

egrep -qi -f <(cat <<'EOF'
/bo/
/sf/
goodreads
EOF
) <<<"$(window_title)" || exit 0

grep -q "/res/" ${tmpdir}/clipboard.txt && exit 0

y "book:"
push
while IFS= read -r line || [[ -n "$line" ]]; do
  y "- name: $line"
done
