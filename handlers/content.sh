#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

TMP_FILE=$(mktemp /tmp/content.XXXXX)

cat > ${TMP_FILE}

file_type=$(file -b ${TMP_FILE})

case ${file_type} in
  "JSON text data")
cat<<EOF
json:
  - path: ${TMP_FILE}
EOF
   ;;
  "ASCII text"|"ASCII text, with CRLF line terminators")

    cat ${TMP_FILE} | yq > /dev/null 2>&1 && {
cat<<EOF
yaml:
  - path: ${TMP_FILE}
EOF
}
  ;;
esac
