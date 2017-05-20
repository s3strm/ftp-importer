#!/usr/bin/env bash
AZ=$(curl 169.254.169.254/latest/meta-data/placement/availability-zone/)
export AWS_DEFAULT_REGION=${AZ::-1}
QUEUE_URL=$(
  aws cloudformation describe-stacks \
    --stack-name s3strm-ftp-importer \
    --query 'Stacks[].Outputs[?OutputKey==`FTPDownloadQueue`].OutputValue' \
    --output text
)
DOWNLOADER_BIN="$(dirname $0)/downloader"

function pop_message() {
  aws sqs receive-message                                             \
    --queue-url ${QUEUE_URL}                                          \
    --query 'Messages[].{receipt_handle: ReceiptHandle, video: Body}' \
    --output text
}

function delete_message() {
  handle="$1"
  aws sqs delete-message          \
    --queue-url ${QUEUE_URL}      \
    --receipt-handle "${handle}"
}

while true; do
  data="$(pop_message)"
  receipt_handle="$(echo "${data}" | awk '{ print $1}')"
  file="$(echo "${data}" | awk '{ print $2}')"

  if [[ "${receipt_handle}" == "None" ]]; then
    echo "no messages available on queue"
    sleep 120
  else
    echo "receipt_handle is '${receipt_handle}'"
    echo "file is '${file}'"
    ${DOWNLOADER_BIN} ${file}
    delete_message "${receipt_handle}"
  fi

  unset data message_id file
done
