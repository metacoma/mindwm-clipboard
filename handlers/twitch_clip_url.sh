#!/usr/bin/env bash

grep_urls() {
  grep -Po '(?i)\bhttps?://(?:clips\.twitch\.tv/[a-z0-9_-]+|(?:www\.)?twitch\.tv/[^/\s]+/clip/[a-z0-9_-]+)(?=\?|#|\s|$)'
}



get_clip_info() {
  local clip_url=$1
  ~/bin/twitch-dl info $slug_id "${clip_url}" --json | jq '{
  slug: (.slug // ""),
  title: (.title // ""),
  createdAt: (.createdAt // ""),
  viewCount: (.viewCount // 0),
  durationSeconds: (.durationSeconds // 0),
  url: (.url // ""),
  category: (.game.name // ""),
  broadcaster: (.broadcaster.login // "")
}'

}

URLS=$(grep_urls) || :
test -n "${URLS}" || exit 0

echo "twitch_clips:"
for url in $URLS;  do
  clip_info=$(get_clip_info ${url})
  echo "  -"
  echo ${clip_info} | yq -y | sed 's/^/    /'
done
