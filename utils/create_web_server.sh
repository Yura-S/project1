#!/bin/bash

function CreateWebServer(){

#--------------------------------------check gived subnet_id
if [ -z $1 ]; then
	echo NOT GIVED SUBNET ID
	exit 1
fi	

ALL_SUBNETS_COUNT=(`aws ec2 describe-subnets --filters --query 'Subnets[].[SubnetId]' --output text | wc -l`)
ALL_SUBNETS=(`aws ec2 describe-subnets --query 'Subnets[].[SubnetId]' --output text`)
for (( i=0; i<$ALL_SUBNETS_COUNT; i++ ))
do
if [ "${ALL_SUBNETS[$i]}" = "$1" ]; then
        break
elif [ $i -eq $((ALL_SUBNETS_COUNT - 1)) ]; then
        echo SUBNET ID IS INCORRECT
	exit 1
fi
done

#--------------------------------------create security group
VPC_ID=`aws ec2 describe-subnets --subnet-id $1 --query Subnets[].VpcId --output text`

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

#--------------------------------------create instance
INSTANCE_ID=`aws ec2 run-instances --image-id ami-0557a15b87f6559cf --count 1 --instance-type t2.micro --security-group-ids $SECURITY_GROUP_ID  --block-device-mappings '[{"DeviceName":"/dev/xvda","Ebs":{"VolumeSize":8,"VolumeType":"gp2"}}]' --subnet-id $1 --query Instances[0].InstanceId --output text`
echo CREATED INSTANCE ID IS - $INSTANCE_ID

#--------------------------------------check instance status
echo CHECKING INSTANCES STATES BEFORE CONTINUE
CHECK=`aws ec2 describe-instance-status --instance-id $INSTANCE_ID --query InstanceStatuses[].SystemStatus[].Details[].Status --output text`
while [ ! "$CHECK" = "passed" ]
do
  echo $CHECK `date`
  CHECK=`aws ec2 describe-instance-status --instance-id $INSTANCE_ID --query InstanceStatuses[].SystemStatus[].Details[].Status --output text`
  sleep 5
done

echo CREATED INSTANCE ID IS - $INSTANCE_ID


#--------------------------------------get instance availability zone

AVAILABILITY_ZONE_ID=`aws ec2 describe-instances --instance-id $INSTANCE_ID --query 'Reservations[].Instances[].Placement.AvailabilityZone' --output text`
echo $AVAILABILITY_ZONE_ID

#--------------------------------------get instance os user

OS_USER=ubuntu
echo REMOTE SERVER USER IS $OS_USER

#--------------------------------------giving public ssh key

aws ec2-instance-connect send-ssh-public-key --instance-id $INSTANCE_ID --availability-zone $AVAILABILITY_ZONE_ID --instance-os-user $OS_USER --ssh-public-key file://~/.ssh/id_rsa.pub
echo GIVED A PUBLIC KEY

#--------------------------------------get public ip

PUBLIC_IP=`aws ec2 describe-instances --instance-id $INSTANCE_ID --query 'Reservations[].Instances[].PublicIpAddress' --output text`
echo PUBLIC IP IS $PUBLIC_IP

#--------------------------------------open ssh connection

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
