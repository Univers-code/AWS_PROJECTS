#!/bin/bash

set -e

echo "Starting Security Group setup..."

# security group server
SG_WEB=$(aws ec2 create-security-group --group-name web-sg --description "Security Group web" --vpc-id vpc-043dcf8249cc358cd --query 'GroupId' --output text)

# Rules
aws ec2 authorize-security-group-ingress --group-id $SG_WEB --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id $SG_WEB --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id $SG_WEB --protocol tcp 
--port 22 --cidr [TU IP/ YOUR IP]/32 > /dev/null

echo "Security Group created web $SG_WEB"

# security group db
SG_DB=$(aws ec2 create-security-group --group-name db-sg --description "security group db" --vpc-id vpc-043dcf8249cc358cd --query 'GroupId' --output text)

# rule
aws ec2 authorize-security-group-ingress --group-id $SG_DB --protocol tcp --port 3306 --source-group $SG_WEB > /dev/null

echo "Security Group created db $SG_DB"


# Tags
aws ec2 create-tags --resources $SG_WEB --tags Key=Name,Value=sg-web
aws ec2 create-tags --resources $SG_DB --tags Key=Name,Value=sg-db

echo "Security Groups configured successfully."

