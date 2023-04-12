#!/bin/bash

#----------------------------------no argument
#source ./utils/create_vpc.sh
#CreateVpc

#----------------------------------argument is subnetid
#source ./utils/create_web_server.sh
#CreateWebServer

#----------------------------------no argument
#source ./utils/create_vpc_and_web_server.sh
#CreateVpcAndWebServer

#----------------------------------no argument
#sourcet ./utils/create_vpc_and_web_server_and_private_server.sh
#CreateVpcAndWebServerAndPrivateServer

#----------------------------------argument is vpc id
source ./utils/delete_vpc.sh
DeleteVpc vpc-06a6fa98092457aa9 
