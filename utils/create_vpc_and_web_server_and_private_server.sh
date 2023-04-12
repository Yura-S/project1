#!/bin/bash

function CreateVpcAndWebServerAndPrivateServer(){

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
#--------------------------------------create public subnet

PUBLIC_SUBNET_ID=`aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --region us-east-1 --query Subnet.SubnetId --output text`
echo CREATED PUBLIC SUBNET ID IS - $PUBLIC_SUBNET_ID
sleep 3

#--------------------------------------create private subnet

PRIVATE_SUBNET_ID=`aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --region us-east-1 --query Subnet.SubnetId --output text`
echo CREATED PRIVATE SUBNET ID IS - $PRIVATE_SUBNET_ID
sleep 3
#--------------------------------------give public id to instances

aws ec2 modify-subnet-attribute --subnet-id $PUBLIC_SUBNET_ID --map-public-ip-on-launch
echo PUBLIC SUBNET IS MODIFIED
sleep 3
#--------------------------------------create route table

ROUTE_TABLE_ID=`aws ec2 create-route-table --vpc-id $VPC_ID --region us-east-1 --query RouteTable.RouteTableId --output text`
echo CREATED ROUTE TABLE ID IS - $ROUTE_TABLE_ID
sleep 3
#--------------------------------------create route

aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr 0.0.0.0/0 --gateway-id $INTERNET_GATEWAY_ID --region us-east-1
echo CREATED ROUTE
sleep 3
#--------------------------------------associate public subnet the route table

aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --region us-east-1 --subnet-id $PUBLIC_SUBNET_ID
echo ROUTE IS ASSOCIATED TO PUBLIC SUBNET
sleep 3
#--------------------------------------associate private subnet the route table

aws ec2 associate-route-table --route-table-id $ROUTE_TABLE_ID --region us-east-1 --subnet-id $PRIVATE_SUBNET_ID
echo ROUTE IS ASSOCIATED TO PRIVATE SUBNET
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
sleep 3
#--------------------------------------create key pair

aws ec2 create-key-pair --key-name demo-key --output text --query "KeyMaterial" --region us-east-1
echo CREATED PAIRING KEY NAME IS - demo-key
sleep 3
#--------------------------------------chmod pair key

chmod 400 ./demo-key.pem
echo GIVING PERMISIONS TO PAIRING KEY FILE
sleep 3
#--------------------------------------create public instance

PUBLIC_INSTANCE_ID=`aws ec2 run-instances --image-id ami-0557a15b87f6559cf --count 1 --instance-type t2.micro --key-name demo-key --security-group-ids $SECURITY_GROUP_ID --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":8,"VolumeType":"gp2"}}]' --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=public_instance}]' --subnet-id $PUBLIC_SUBNET_ID --region us-east-1 --query Instances[0].InstanceId --output text`

#--------------------------------------create private instance

PRIVATE_INSTANCE_ID=`aws ec2 run-instances --image-id ami-0557a15b87f6559cf --count 1 --instance-type t2.micro --key-name demo-key --security-group-ids $SECURITY_GROUP_ID --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":8,"VolumeType":"gp2"}}]' --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=private_instance}]' --subnet-id $PRIVATE_SUBNET_ID --region us-east-1 --query Instances[0].InstanceId --output text`


#--------------------------------------check instances states

echo CHECKING INSTANCES STATES BEFORE CONTINUE
CHECK1=`aws ec2 describe-instance-status --instance-id $PUBLIC_INSTANCE_ID --query InstanceStatuses[].SystemStatus[].Details[].Status --output text`
CHECK2=`aws ec2 describe-instance-status --instance-id $PRIVATE_INSTANCE_ID --query InstanceStatuses[].SystemStatus[].Details[].Status --output text`
while [ ! "$CHECK1" = "passed" ] || [ ! "$CHECK2" = "passed" ]
do
  echo $CHECK1 `date`
  echo $CHECK2 `date`
  CHECK1=`aws ec2 describe-instance-status --instance-id $PUBLIC_INSTANCE_ID --query InstanceStatuses[].SystemStatus[].Details[].Status --output text`
  CHECK2=`aws ec2 describe-instance-status --instance-id $PRIVATE_INSTANCE_ID --query InstanceStatuses[].SystemStatus[].Details[].Status --output text`
  sleep 5
done

echo CREATED PRIVATE INSTANCE ID IS - $PRIVATE_INSTANCE_ID
echo CREATED PUBLIC INSTANCE ID IS - $PUBLIC_INSTANCE_ID

#--------------------------------------get instance availability zone

AVAILABILITY_ZONE_ID=`aws ec2 describe-instances --instance-id $PUBLIC_INSTANCE_ID --query 'Reservations[].Instances[].Placement.AvailabilityZone' --output text`
echo $AVAILABILITY_ZONE_ID

#--------------------------------------get public instance os user

OS_USER=ubuntu
echo REMOTE SERVER USER IS $OS_USER

#--------------------------------------giving public ssh key to public instance

aws ec2-instance-connect send-ssh-public-key --instance-id $PUBLIC_INSTANCE_ID --availability-zone $AVAILABILITY_ZONE_ID --instance-os-user $OS_USER --ssh-public-key file://~/.ssh/id_rsa.pub
echo GIVED A PUBLIC KEY

#--------------------------------------get public ip of public instance

PUBLIC_IP=`aws ec2 describe-instances --filters Name=vpc-id,Values=$VPC_ID --filters 'Name=tag:Name,Values=public_instance' --query 'Reservations[].Instances[].PublicIpAddress' --output text`
echo PUBLIC IP IS $PUBLIC_IP

#--------------------------------------open ssh connection

#chmod 700 ~/.ssh/id_rsa
ssh -o "StrictHostKeyChecking no" -i ~/.ssh/id_rsa ${OS_USER}@${PUBLIC_IP} \
'
echo '' | sudo -S \
sudo apt-get    update; \
sudo apt -y install nginx; \
sudo chmod 777 /var/www/html/index.nginx-debian.html; \
sudo cat << _EOF_ > /var/www/html/index.nginx-debian.html;
<!DOCTYPE html>
<html>
<head>
</head>
<body>
<p id="date"></p>
<script>
document.getElementById("date").innerHTML = Date()
</script>
</body>
</html>
_EOF_
'	

}
