export MOVIES_BUCKET = $(shell aws cloudformation list-exports --query 'Exports[?Name==`s3strm-movies-bucket`].Value' --output text)
export QUEUE_URL = $(shell aws cloudformation list-exports --query 'Exports[?Name==`s3strm-ftp-download-queue`].Value' --output text)

include ../../settings
export FTP_USERNAME
export FTP_PASSWORD
export FTP_HOSTNAME
export FTP_PORT
export FTP_PATH

test:
	python ./src/lambda.py

