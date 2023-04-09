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
