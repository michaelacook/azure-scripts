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

az vmss create --name $VMSS \
    --resource-group $RG \
    --image Ubuntu2204 \
    --vm-sku Standard_DC1s_v2 \
    --vnet-name $VNET \
    --subnet $SN \
    --nsg $NSG \
    --admin-username michael \
    --generate-ssh-keys

az network lb rule create --name "$LB-HTTP-rule" \
    --resource-group $RG \
    --lb-name api-demo-scalesetLB \
    --backend-pool-name "$LB-BackendPool" \
    --backend-port 5000 \
    --frontend-ip-name api-demo-scalesetLBPublicIP \
    --frontend-port 80 \
    --protocol tcp


# create VM scale set and add to lb backend pool