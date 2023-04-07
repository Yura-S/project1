#!/bin/bash

#--------------------------------------get instance id

INSTANCE_ID=`aws ec2 describe-instances --filters Name=vpc-id,Values=$1 --query 'Reservations[].Instances[].InstanceId' --output text`
echo start delete instance with instance id $INSTANCE_ID

#--------------------------------------delete ec2

aws ec2 terminate-instances --instance-ids $INSTANCE_ID
echo INSTANCE $INSTANCE_ID DELETED
echo SLEEPING TWO MINUTES WHILE INSTANCE TERMINATING
sleep 120

#--------------------------------------get security groups ids

SECURITY_GROUP_ID_1=`aws ec2 describe-security-groups --filters Name=vpc-id,Values=$1 --query 'SecurityGroups[0].GroupId' --output text`
echo $SECURITY_GROUP_ID_1

SECURITY_GROUP_ID_2=`aws ec2 describe-security-groups --filters Name=vpc-id,Values=$1 --query 'SecurityGroups[1].GroupId' --output text`
echo $SECURITY_GROUP_ID_2

#--------------------------------------delete security groups

echo DELETING SECURITY GROUP $SECURITY_GROUP_ID_1
aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID_1
sleep 3

echo DELETING SECURITY GROUP $SECURITY_GROUP_ID_2
aws ec2 delete-security-group --group-id $SECURITY_GROUP_ID_2
sleep 3

#--------------------------------------delete security key

aws ec2 delete-key-pair --key-name demo-key
echo PAIRING KEY demo-key DELETED
sleep 3

#--------------------------------------get subnet id

SUBNET_ID=`aws ec2 describe-subnets --filters Name=vpc-id,Values=$1 --query Subnets[].SubnetId --output text`
echo subnet id is $SUBNET_ID

#--------------------------------------delete subnet

aws ec2 delete-subnet --subnet-id $SUBNET_ID
echo SUBNET $SUBNET_ID DELETED
sleep 3

#--------------------------------------get route table id

ROUTE_TABLE_ID_1=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=$1 --query RouteTables[0].RouteTableId --output text`
echo $ROUTE_TABLE_ID_1

ROUTE_TABLE_ID_2=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=$1 --query RouteTables[1].RouteTableId --output text`
echo $ROUTE_TABLE_ID_2

#--------------------------------------delete route tables

echo DELETING ROUTE TABLE $ROUTE_TABLE_ID_1
aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID_1
sleep 3

echo DELETING ROUTE TABLE $ROUTE_TABLE_ID_1
aws ec2 delete-route-table --route-table-id $ROUTE_TABLE_ID_2
sleep 3

#--------------------------------------get internet gateway id

INTERNET_GATEWAY_ID=`aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$1 --query InternetGateways[].InternetGatewayId --output text`
echo INTERNET GATEWAY ID IS $INTERNET_GATEWAY_ID

#--------------------------------------detach internet gateway

aws ec2 detach-internet-gateway --internet-gateway-id $INTERNET_GATEWAY_ID --vpc-id $1
echo INTERNET GATEWAY $INTERNET_GATEWAY_ID DETACHED FROM VPC $1
sleep 3

#--------------------------------------delete internet gateway

aws ec2 delete-internet-gateway --internet-gateway-id $INTERNET_GATEWAY_ID
echo INTERNET GATEWAY $INTERNET_GATEWAY_ID DELETED
sleep 3

#--------------------------------------delete vpc

aws ec2 delete-vpc --vpc-id $1
echo VPC $I DELETED
