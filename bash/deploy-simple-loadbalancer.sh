#!/bin/bash

# This script sets up a simple Linux vm scale set behind a load balancer translating port 80 to 5000
# The purpose is to allow the API to run without root permissions for security purposes and ease of deployment

RG='api-demo-rg'
LOC='eastus'
LB='api-demo-lb'
VNET='api-demo-vnet'
SN='LBBackendPoolSubnet'
NSG='api-demo-nsg'
LB_IP='api-demo-lb-ip'
VMSS='api-demo-scaleset'

az group create --name $RG --location $LOC

az network vnet create --name $VNET \
    --resource-group $RG \
    --location $LOC \
    --address-prefixes 10.0.0.0/16 \
    --subnet-name $SN \
    --subnet-prefixes 10.0.1.0/24

# Create an NSG with port 5000 inbound opened
az network nsg create --name $NSG \
    --resource-group $RG \
    --location $LOC

az network nsg rule create --name AllowPort5000 \
    --nsg-name $NSG \
    --resource-group $RG \
    --priority 100 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp

az network public-ip create --name $LB_IP \
    --resource-group $RG \
    --location $LOC \
    --sku Standard

# manually create the load balancer and assign it the above IP
az network lb create --name $LB \
    --resource-group $RG \
    --sku Standard \
    --public-ip-address $LB_IP \
    --frontend-ip-name "${LB_IP}-frontend" \
    --backend-pool-name DefaultBackendPool

# wait 3 minutes because it seems the commands below are running before the lb is successfully running
sleep 180

az network lb probe create --name "${LB}-probe" \
    --resource-group $RG \
    --lb-name $LB \
    --protocol tcp \
    --port 5000

az network lb rule create --name "$LB-HTTP-rule" \
    --resource-group $RG \
    --lb-name $LB \
    --backend-pool-name "$LB-BackendPool" \
    --backend-port 5000 \
    --frontend-ip-name "${LB_IP}-frontend" \
    --frontend-port 80 \
    --protocol tcp
# set the load balancer as the LB for the scaleset

az vmss create --name $VMSS \
    --resource-group $RG \
    --image Ubuntu2204 \
    --vm-sku Standard_DC1s_v2 \
    --vnet-name $VNET \
    --subnet $SN \
    --nsg $NSG \
    --admin-username michael \
    --generate-ssh-keys \
    --lb $LB