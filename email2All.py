import logging
import boto3
from botocore.exceptions import ClientError
from time import sleep
import json
import csv

USERPOOL_ID = "us-east-1_xxxxx"

AWS_REGION = "us-east-1"
SUBJECT = "Server Maintain time window"
CHARSET = "UTF-8"
SENDER = "Hogwarts <tester@email.com>"

def send_email(username, email):

    RECIPIENT = email
    BODY_TEXT = ("Hello, we are going to maintain our server from xxx to xxx")
    BODY_HTML = """<html>
    <head></head>
    <body>
    <h1>Notice</h1>
    <p>We are going to maintain our server from xxx to xxx</p>"""

    sesclient = boto3.client('ses',region_name=AWS_REGION)

    try:
        #Provide the contents of the email.
        response = sesclient.send_email(
            Destination={
                'ToAddresses': [
                    RECIPIENT,
                ],
            },
            Message={
                'Body': {
                    'Html': {
                        'Charset': CHARSET,
                        'Data': BODY_HTML,
                    },
                    'Text': {
                        'Charset': CHARSET,
                        'Data': BODY_TEXT,
                    },
                },
                'Subject': {
                    'Charset': CHARSET,
                    'Data': SUBJECT,
                },
            },
            Source=SENDER,
        )
    # Display an error if something goes wrong.	
    except ClientError as e:
        print(e.response['Error']['Message'])
        RESBODY = json.dumps(e.response['Error']['Message'])
        RESCODE=400
    else:
        print("Email sent! Message ID:"),
        print(response['MessageId'])

def main():

    client = boto3.client('cognito-idp')

    response = client.list_users(
        UserPoolId=USERPOOL_ID
    )
    
    i = len(response["Users"])
    pageToken =''
    if (i > 59) :
        pageToken = response["PaginationToken"]
    
    for user in response["Users"]:
        print (user["Username"])
        userName = user["Username"]
        email = ''
        for attr in user["Attributes"]:
            if "email" == attr["Name"]: 
                print (attr["Value"])
                email = attr["Value"]
                break
        send_email (userName, email)

    while i > 59:
        sleep(0.05)

        pageToken = response["PaginationToken"]
        response = client.list_users(
            UserPoolId=USERPOOL_ID,
            PaginationToken=pageToken,
        )

        i = len(response["Users"])

        for user in response["Users"]:
            print (user["Username"])
            userName = user["Username"]
            email = ''
            for attr in user["Attributes"]:
                if "email" == attr["Name"]: 
                    print (attr["Value"])
                    email = attr["Value"]
                    break
            send_email (userName, email)
    

if __name__ == '__main__':
    main()
