#!/usr/bin/env bash

TMP_CLIPBOARD_FILE=$(mktemp /tmp/clipboard.XXXXXXX)

cat > ${TMP_CLIPBOARD_FILE}
clipboard=$(cat ${TMP_CLIPBOARD_FILE})

if [ "$clipboard" = "ubuntu@hw0076" ]; then
  echo 172.25.0.2
  exit
fi

cat ${TMP_CLIPBOARD_FILE}
