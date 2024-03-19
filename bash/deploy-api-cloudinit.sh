#!/bin/bash

# This script creates a Linux virtual machine in a vnet
# and uses cloud-init to deploy a sample REST API from a GitHub repo

RG='cloudinit-demo-rg'
VM='cloudinit-demo-vm'
LOC='eastus'
VMADMIN='michael'

az group create --name $RG --location $LOC

az vm create --resource-group $RG \
--name $VM \
--image Ubunbu2204 \
--admin-username $VMADMIN \
--generate-ssh-keys \
--custom-data deploy-api.txt

az vm open-port --port 80 --resource-group $RG --name $VM