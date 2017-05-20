#!/usr/bin/env bash
QUEUE_URL=TODO

function log() {
  message=$@
}

function pop_message() {
  aws sqs receive-message     \
    --queue-url ${QUEUE_URL}  \
    --queue 'Messages[].Body' \
    --output text
}

function download() {
  file=$1
  log "Downloading ${file} from FTP"
}

function upload() {
  file=$1
  log "Uploading ${file} to S3"
}

function delete() {
  file=$1
  log "Deleting ${file} from FTP"
}

while true; do
  file=$(pop_message)

  if [[ -z ${file} ]]; then
    log "There were no messages on the queue for downloading"
  else
    download ${file}
    upload ${file}
    delete ${file}
  fi

  unset file
  sleep 120
done
