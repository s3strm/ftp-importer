#!/usr/bin/env bash
AZ=$(curl 169.254.169.254/latest/meta-data/placement/availability-zone/)
export AWS_DEFAULT_REGION=${AZ::-1}
export INSTANCE_ID

export MOVIES_BUCKET=$(
  aws cloudformation list-exports \
    --query 'Exports[?Name==`s3strm-movies-bucket`].Value' \
    --output text
)

QUEUE_URL=$(
  aws cloudformation describe-stacks \
    --stack-name s3strm-ftp-importer \
    --query 'Stacks[].Outputs[?OutputKey==`FTPDownloadQueue`].OutputValue' \
    --output text
)
DOWNLOADER_BIN="$(dirname $0)/downloader"

export FTP_USERNAME=$(
  aws cloudformation describe-stacks \
    --stack-name s3strm-ftp-importer \
    --query 'Stacks[].Outputs[?OutputKey==`FtpUsername`].OutputValue' \
    --output text
)

export FTP_PASSWORD=$(
  aws cloudformation describe-stacks \
    --stack-name s3strm-ftp-importer \
    --query 'Stacks[].Outputs[?OutputKey==`FtpPassword`].OutputValue' \
    --output text
)

export FTP_HOSTNAME=$(
  aws cloudformation describe-stacks \
    --stack-name s3strm-ftp-importer \
    --query 'Stacks[].Outputs[?OutputKey==`FtpHostname`].OutputValue' \
    --output text
)

export FTP_PATH=$(
  aws cloudformation describe-stacks \
    --stack-name s3strm-ftp-importer \
    --query 'Stacks[].Outputs[?OutputKey==`FtpPath`].OutputValue' \
    --output text
)

export LOG_GROUP=$(
  aws cloudformation describe-stacks \
    --stack-name s3strm-ftp-importer \
    --query 'Stacks[].Outputs[?OutputKey==`LogGroup`].OutputValue' \
    --output text
)

export INSTANCE_ID=$(curl 169.254.169.254/latest/meta-data/instance-id)

aws logs create-log-stream \
  --log-stream-name ${INSTANCE_ID} \
  --log-group-name ${LOG_GROUP}

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
  receipt_handle="$(echo "${data}" | awk '{ print $1 }')"
  file="$(echo "${data}" | awk '{ print $2 }')"

  if [[ "${receipt_handle}" == "None" ]]; then
    echo "no messages available on queue"
    sleep 120
  else
    echo "receipt_handle is '${receipt_handle}'"
    echo "file is '${file}'"
    if ${DOWNLOADER_BIN} ${file}; then
      delete_message "${receipt_handle}"
    else
      echo "failed to process ${file}"
    fi
  fi

  unset data message_id file
done
