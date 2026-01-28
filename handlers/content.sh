#!/usr/bin/env bash


SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

file_type_normalize() {
  awk '
  {
    line=$0
    # remove numbers
    gsub(/\([^)]+\)/, "", line)

    # remove tails
    sub(/,? with .*/, "", line)

    # убрать архитектуру / размеры / детали
    sub(/, [0-9].*/, "", line)

    sub(/JSON text data/, "JSON text", line)
    sub(/ELF .* executable/, "ELF executable", line)
    sub(/ image data.*/, " image", line)
    gsub(/  +/, " ", line)
    gsub(/, $/, "", line)

    print line
  }
  '
}


TMP_FILE=$(mktemp /tmp/content.XXXXX)

cat > ${TMP_FILE}

file_type=$(file -b ${TMP_FILE} | file_type_normalize)

case ${file_type} in
  "JSON text")
cat<<EOF
json:
  - path: ${TMP_FILE}
EOF
   ;;
   "ASCII text")
cat<<EOF
text:
  - path: ${TMP_FILE}
EOF
   ;;
   "Unicode text, UTF-8 text")
cat<<EOF
text:
  - path: ${TMP_FILE}
EOF
   ;;
esac
