#!/usr/bin/env bash
set -x

PATH=${PATH}:~/bin:$(pwd)/bin

case $1 in
    clipboard)
        notify_selection=clipboard
        xclip_selection=--primary
    ;;
    qt)
        notify_selection=clipboard
        xclip_selection=--clipboard
    ;;
    primary)
        notify_selection=primary
        xclip_selection=--primary
    ;;
esac

while clipnotify -s ${notify_selection}; do
    echo "new clipboard"
    test -f /tmp/skip_next_clipboard && {
        rm /tmp/skip_next_clipboard
        continue
    }
    xclip ${xclip_selection} -o | tee | bin/filter.sh > /tmp/clipboard.txt
    tmpdir="$(mktemp -d)"
    export tmpdir
    rm input.yaml
    cat /tmp/clipboard.txt | ./run_scripts.sh handlers ${tmpdir}
    cat ${tmpdir}/*.yaml | tee input.yaml
    if [ -s input.yaml ]; then
      kcl run ./menu.k --format json > menus.json
      CHECKSUM_FILE="/tmp/kando_menu.$(md5sum ./menus.json | cut -d" " -f1)"
      export CHECKSUM_FILE
      cp ./menus.json ${CHECKSUM_FILE}
      mv menus.json ~/.config/kando/menus.json
      kando -m root &
      cat ${CHECKSUM_FILE} | ./run_scripts.sh posthooks ${CHECKSUM_FILE}

    fi
done
