#!/usr/bin/env bash

twitch_streamer() {
  grep -oiP '(twitch\.tv/|@)[a-z0-9_]{4,25}' \
  | sed -E 's#^(twitch\.tv/|@)##' \
  | tr '[:upper:]' '[:lower:]' \
  | sort -u
}

streamers=$(twitch_streamer) || :

test -n "${streamers}" || exit 0

echo "twitch_streamer:"
for streamer in ${streamers}; do
    echo "  - name: ${streamer}"
done
