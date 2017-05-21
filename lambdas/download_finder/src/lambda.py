from __future__ import print_function
import ast
import boto3
import os
import re
from ftplib import FTP

def downloadable_files():
    ftp = FTP(os.environ["FTP_HOSTNAME"])
    ftp.login(
            os.environ["FTP_USERNAME"],
            os.environ["FTP_PASSWORD"],
            )

    ftp.cwd(os.environ["FTP_PATH"])

    try:
        files = ftp.nlst("tt???????.???")
        ftp.close
    except:
        return []

    return files

def add_to_queue(file):
    client = boto3.client('sqs')

    print("queuing {} for download".format(file))
    response = client.send_message(
        QueueUrl=os.environ["QUEUE_URL"],
        MessageBody=file,
    )

def lambda_handler(event, context):
    for file in downloadable_files():
        add_to_queue(file)

if __name__ == "__main__":
    print(lambda_handler({}, {}))
