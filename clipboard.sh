#!/usr/bin/env bash
set -x

PATH=${PATH}:~/bin:$(pwd)/bin

. ./.env
. handlers/utils.sh

case $1 in
    clipboard)
        notify_selection=clipboard
        xclip_selection=clipboard
    ;;
    qt)
        notify_selection=clipboard
        xclip_selection=clipboard
    ;;
    primary)
        notify_selection=primary
        xclip_selection=primary
    ;;
esac

while clipnotify -s ${notify_selection}; do
    echo "new clipboard"
    tmpdir="$(mktemp -d)"
    export tmpdir
    bin/window_info.sh > ${tmpdir}/window.json
    test -f /tmp/skip_next_clipboard && {
        rm /tmp/skip_next_clipboard
        continue
    }
    win_title=$(window_title)
    echo ${win_title} | egrep -f ignore.txt && {
      echo "Ignore window ${win_title}"
      continue
    }

    (xclip -selection ${xclip_selection} -o | tee | bin/filter.sh; echo )| tee ${tmpdir}/clipboard.txt > /tmp/clipboard.txt

    rm input.yaml
    cat /tmp/clipboard.txt | ./run_scripts.sh handlers ${tmpdir}
    cat ${tmpdir}/*.yaml > input.yaml
    if [ -s input.yaml ]; then
      kcl run ./menu.k --format json > menus.json || continue
      CHECKSUM_FILE="/tmp/kando_menu.$(md5sum ./menus.json | cut -d" " -f1)"
      export CHECKSUM_FILE
      cp ./menus.json ${CHECKSUM_FILE}
      pkill -9 -f kando
      cp menus.json ~/.config/kando/menus.json
      kando -m root &
      cat ${CHECKSUM_FILE} | ./run_scripts.sh posthooks ${tmpdir}
    fi
done
