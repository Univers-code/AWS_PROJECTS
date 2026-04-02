#!/bin/bash

set -e

echo "Creando Vpc ...."

# Vpc
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
aws ec2 wait vpc-available --vpc-ids $VPC_ID

aws ec2 create-tags --resources $VPC_ID --tag Key=Project,Value=aws-network


echo "Creando subnets..."

# Subnet Publica
SUBNET_PUBLIC=$(aws ec2 create-subnet --cidr-block 10.0.1.0/24 --vpc-id $VPC_ID --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
aws ec2 create-tags --resources $SUBNET_PUBLIC --tag Key=Project,Value=aws-network


# Subnet Privada
SUBNET_PRIV=$(aws ec2 create-subnet --cidr-block 10.0.2.0/24 --vpc-id $VPC_ID --query 'Subnet.SubnetId' --availability-zone us-east-1b --output text)
aws ec2 create-tags --resources $SUBNET_PRIV --tag Key=Project,Value=aws-network

# ip publica automatica
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_PUBLIC --map-public-ip-on-launch


# Gateway
echo "Creando InternetGateWay......."
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
aws ec2 create-tags --resources $IGW_ID --tag Key=Project,Value=aws-network



echo "Creando route-table y asociando...."

# Route Table, route y associate
RTB_PUBLIC=$(aws ec2 create-route-table --vpc-id $VPC_ID --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id $RTB_PUBLIC --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --subnet-id $SUBNET_PUBLIC --route-table-id $RTB_PUBLIC
aws ec2 create-tags --resources $RTB_PUBLIC --tag Key=Project,Value=aws-network


echo "Infraestructura creada correctamente"

echo "Vpc: $VPC_ID"
echo "subnet publica: $SUBNET_PUBLIC"
echo "subnet privada: $SUBNET_PRIV"
echo "Internet Gateway: $IGW_ID"
echo "Route Table: $RTB_PUBLIC"
