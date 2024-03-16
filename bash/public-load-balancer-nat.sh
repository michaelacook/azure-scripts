#!/bin/bash

# This script is adapted from the Microsoft Learn Quickstart guide for creating
# a public load balancer and a NAT gateway with a Bastion.
# I have modified the script for learning purposes.


RG='public-lb-rg'
LOCATION='eastus'
VNET='public-lb-vnet'
SUBNET='BackendPoolSubnet'
IPNAME='FrontEndLBIP'
LBNAME='demo-load-balancer'
LBBACKENDPOOLNAME='DefaultBackendPool'
PROBENAME='DefaultHealthProbe'
LBRULENAME='DefaultHTTPRule'
BACKENDPOOLNSGNAME='BackendPoolNSG'
BATIONSUBNET='AzureBastionSubnet'
BASTIONIP='BastionPublicIP'
BACKENDVM1='VM1'
BACKENDVM2='VM2'
BACKENDVMIMAGE='win2019datacenter'
BACKENDVMADMIN='michael'
NATNAME='lb-demo-natgateway'
NATPUBLICIPNAME='nat-public-ip'

az group create --name $RG --location $LOCATION

az network vnet create --name $VNET \
--resource-group $RG \
--location $LOCATION \
--address-prefixes 10.1.0.0/16 \
--subnet-name $SUBNET \
--subnet-prefixes 10.1.0.0/24

# Public IP address for the front end of the load balancer
az network public-ip create --resource-group $RG \
--name $IPNAME \
--sku Standard \
--zone 1 2 3

# Create the public load balancer
az network lb create \
--resource-group $RG \
--name $LBNAME \
--sku Standard \
--public-ip-address $IPNAME \
--frontend-ip-name $IPNAME \
--backend-pool-name $LBBACKENDPOOLNAME

# Create the health probe for the LB
az network lb probe create --resource-group $RG \
--lb-name $LBNAME \
--name $PROBENAME \
--protocol tcp \
--port 80

# Create load balancer rule
az network lb rule create --resource-group $RG \
--lb-name $LBNAME \
--name $LBRULENAME \
--protocol tcp \
--frontend-port 80 \
--backend-port 80 \
--frontend-ip-name $IPNAME \
--backend-pool-name $LBBACKENDPOOLNAME \
--probe-name $PROBENAME \
--disable-outbound-snat true \
--idle-timeout 15 \
--enable-tcp-reset true

# Create NSG for backend pool VM nics
az network nsg create --resource-group $RG --name $BACKENDPOOLNSGNAME
# Add the necessary rule
az network nsg rule create --resource-group $RG --nsg-name $BACKENDPOOLNSGNAME \
--name BackendPoolNSGHTTPRule \
--protocol '*' \
--direction inbound \
--source-address-prefix '*' \
--source-port-range '*' \
--destination-address-prefix '*' \
--destination-port-range 80 \
--access allow \
--priority 200

# Create a bastion host. This is for securely accessing backend pool VMs 
# without giving them public IPs
az network public-ip create --resource-group $RG \
--name $BASTIONIP \
--sku Standard \
--zone 1 2 3

az network vnet subnet create --resource-group $RG \
--name $BATIONSUBNET \
--vnet-name $VNET \
--address-prefix 10.1.1.0/27

az network bastion create --resource-group $RG \
--name LBDemoBastionHost \
--public-ip-address $BASTIONIP \
--vnet-name $VNET \
--location $LOCATION    

# Create backend pool VMs

# NICs
array=($BACKENDVM1 $BACKENDVM2)
for VM in "${array[@]}"
do
    az network nic create --resource-group $RG \
    --name "$VM-nic" \
    --vnet-name $VNET \
    --subnet $SUBNET \
    --network-security-group $BACKENDPOOLNSGNAME
done

# VMs
az vm create --resource-group $RG \
--name $BACKENDVM1 \
--nics "$BACKENDVM1-nic" \
--image $BACKENDVMIMAGE \
--admin-username $BACKENDVMADMIN \
--zone 1 \
--no-wait

az vm create --resource-group $RG \
--name $BACKENDVM2 \
--nics "$BACKENDVM2-nic" \
--image $BACKENDVMIMAGE \
--admin-username $BACKENDVMADMIN \
--zone 2 \
--no-wait

# Add VMs to the load balancer backend pool
array=("$BACKENDVM1-nic" "$BACKENDVM2-nic")
for NIC in "${array[@]}"
do
    az network nic ip-config address-pool add --resource-group $RG \
    --address-pool $LBBACKENDPOOLNAME \
    --ip-config-name ipconfig1 \
    --nic-name $NIC \
    --lb-name $LBNAME
done

# Create NAT gateway for outbound internet access from the backend pool

# NAT public ip
az network public-ip create --resource-group $RG \
--name $NATPUBLICIPNAME \
--sku Standard \
--zone 1 2 3

# NAT gateway resource
az network nat gateway create --resource-group $RG \
--name $NATNAME \
--public-ip-addresses $NATPUBLICIPNAME \
--idle-timeout 10

# Associate NAT with backend pool subnet
az network vnet subnet update --resource-group $RG \
--vnet-name $VNET \
--name $SUBNET \
--nat-gateway $NATNAME