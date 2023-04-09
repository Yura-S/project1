#!/bin/bash

#--------------------------------------install cli
#sudo apt install awscli
#
#--------------------------------------configure
#aws configure  
#
#stex petqa mej@ lracnel` cat ~/.aws/credentials - tvyaler@ sranic. region@` us-east-1
#
#--------------------------------------create vpc

VPC_ID=`aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text`
echo CREATED VPC ID IS - $VPC_ID
sleep 3
#--------------------------------------create internet gateway

INTERNET_GATEWAY_ID=`aws ec2 create-internet-gateway --region us-east-1 --query InternetGateway.InternetGatewayId --output text`
echo CREATED INTERNET GATEWAY ID IS - $INTERNET_GATEWAY_ID
sleep 3
#--------------------------------------attach internet gateway

aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $INTERNET_GATEWAY_ID --region us-east-1
echo INTERNET GATEWAY ATTACHED TO VPC
sleep 3
#--------------------------------------create subnet

SUBNET_ID=`aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.0.0/24 --region us-east-1 --query Subnet.SubnetId --output text`
echo CREATED SUBNET ID IS - $SUBNET_ID
sleep 3
#--------------------------------------give public id to instances

aws ec2 modify-subnet-attribute --subnet-id $SUBNET_ID --map-public-ip-on-launch
echo SUBNET IS MODIFIED
sleep 3
#--------------------------------------create route table

ROUTE_TABLE_ID=`aws ec2 create-route-table --vpc-id $VPC_ID --region us-east-1 --query RouteTable.RouteTableId --output text`
echo CREATED ROUTE TABLE ID IS - $ROUTE_TABLE_ID
sleep 3
#--------------------------------------create route

aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr 0.0.0.0/0 --gateway-id $INTERNET_GATEWAY_ID --region us-east-1
echo CREATED ROUTE
sleep 3
#--------------------------------------associate the route table

aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --region us-east-1 --subnet-id $SUBNET_ID
echo ROUTE IS ASSOCIATED TO SUBNET
sleep 3
#--------------------------------------create security group

SECURITY_GROUP_ID=`aws ec2 create-security-group --group-name demo-sg --vpc-id $VPC_ID --region us-east-1 --description "testsecgroup" --query GroupId --output text`
echo CREATED SECURITY GROUP ID IS - $SECURITY_GROUP_ID
sleep 3
#--------------------------------------authorize security group

aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region us-east-1
echo OPENING PORT 80 IN SECURITY GROUP
sleep 3
aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 --region us-east-1
echo OPENING PORT 22 IN SECURITY GROUP
sleep 4
#--------------------------------------create key pair

aws ec2 create-key-pair --key-name demo-key --output text --query "KeyMaterial" --region us-east-1 > ./demo-key.pem
echo CREATED PAIRING KEY NAME IS - demo-key

