#!/bin/bash

# Author: Michael Cook <mcook0775@gmail.com>
# Stand up a basic network for testing and lab purposes
# Test script for learning purposes

echo "Resource group name: "
read RGNAME

echo "Azure region: "
read AZUREREGION

echo "Virtual network name: "
read VNETNAME

echo "VM username: "
read VMUSER

echo "VM password: "
read -s VMPASS

az group create --name $RGNAME --location $AZUREREGION

az network vnet create --name $VNETNAME --resource-group $RGNAME --address-prefix 10.0.0.0/16 --subnet-name subnet-1 --subnet-prefixes 10.0.0.0/24
az network vnet subnet create --name subnet-2 --resource-group $RGNAME --vnet-name $VNETNAME --address-prefix 10.0.1.0/24

az network public-ip create --resource-group $RGNAME --name public-ip-1 --sku Standard --location $AZUREREGION
az network public-ip create --resource-group $RGNAME --name public-ip-2 --sku Standard --location $AZUREREGION

az vm create \
--resource-group $RGNAME \
--admin-username $VMUSER \
--authentication-type password \
--admin-password $VMPASS \
--name WinSrv1 --image Win2019Datacenter \
--public-ip-address public-ip-1 \
--vnet-name $VNETNAME \
--subnet subnet-1

az vm create \
--resource-group $RGNAME \
--admin-username $VMUSER \
--authentication-type password \
--admin-password $VMPASS \
--name WinSrv2 \
--image Win2019Datacenter \
--public-ip-address public-ip-2 \
--vnet-name $VNETNAME \
--subnet subnet-2