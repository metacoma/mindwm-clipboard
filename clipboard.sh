#!/usr/bin/env bash
set -x

PATH=${PATH}:~/bin:$(pwd)/bin

case $1 in
    clipboard)
        notify_selection=clipboard
        xclip_selection=primary
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
    test -f /tmp/skip_next_clipboard && {
        rm /tmp/skip_next_clipboard
        continue
    }
    xclip -s ${xclip_selection} -o | tee > /tmp/clipboard.txt
    tmpdir="$(mktemp -d)"
    export tmpdir
    rm input.yaml
    bash ./handlers.sh ${tmpdir}
    cat ${tmpdir}/*.yaml | tee input.yaml
    if [ -s input.yaml ]; then
      kcl run ./menu.k --format json > menus.json
      mv menus.json ~/.config/kando/menus.json
      kando -m root &
    fi
done
