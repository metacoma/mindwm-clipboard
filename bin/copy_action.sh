#!/usr/bin/env bash

TMP_FILE=/tmp/new_clipboard.txt

cat > ${TMP_FILE}

touch /tmp/skip_next_clipboard
cat ${TMP_FILE} | xclip -i -selection primary

cat ${TMP_FILE}  | osd_cat \
    --pos=middle \
    --align=center \
    --font='-misc-fixed-bold-r-normal--120-*-*-*-*-*-*-*' \
    --colour=white \
    --shadow=2 \
    --outline=2 \
    --delay=2 &
