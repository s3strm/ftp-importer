#!/usr/bin/env bash
QUEUE_URL=TODO
DOWNLOADER_BIN="$(dirname $0)/downloader"

while true; do
  file=$(pop_message)
  [[ -z ${file} ]] || ${DOWNLOADER_BIN} ${file}
  unset file
  sleep 120     # use long-polling so that sleeping isn't needed
done
