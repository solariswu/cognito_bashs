import logging
import boto3
from botocore.exceptions import ClientError
from time import sleep
import json
import csv

def main():

    client = boto3.client('cognito-idp')
    UserPool_Id = "us-east-1_xxxxxxxx"

    userData = open('./UserData.csv', 'w')
    csvwriter = csv.writer(userData)

    csvwriter.writerow (['User Name', "Email"])

    response = client.list_users(
        UserPoolId=UserPool_Id
    )
    
    i = len(response["Users"])
    pageToken = response["PaginationToken"]

    for user in response["Users"]:
        print (user["Username"])
        userName = user["Username"]
        email = ''
        for attr in user["Attributes"]:
            if "email" == attr["Name"]: 
                print attr["Value"]
                email = attr["Value"]
                break
        csvwriter.writerow ([userName, email])

    while i > 59:
        sleep(0.05)

        pageToken = response["PaginationToken"]
        response = client.list_users(
            UserPoolId=UserPool_Id,
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
            csvwriter.writerow ([userName, email])
    
    userData.close()

if __name__ == '__main__':
    main()
