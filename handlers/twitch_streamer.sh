#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

twitch_streamer() {
  grep -oiP '(twitch\.tv/|@)[a-z0-9_]{4,25}' \
  | sed -E 's#^(twitch\.tv/|@)##' \
  | tr '[:upper:]' '[:lower:]' \
  | sort -u
}

streamers=$(twitch_streamer) || :

test -n "${streamers}" || exit 0

y "twitch_streamer:"
push
for streamer in ${streamers}; do
    y "- name: ${streamer}"
done
