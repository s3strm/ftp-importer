#!/usr/bin/env bash
QUEUE_URL=TODO
DOWNLOADER_BIN="$(dirname $0)/downloader"

while true; do
  file=$(pop_message)

  if [[ ! -z ${file} ]]; then
    ${DOWNLOADER_BIN} ${file}
  fi

  unset file
  sleep 120
done
