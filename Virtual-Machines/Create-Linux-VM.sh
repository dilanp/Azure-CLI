#=============================Create a VM using a detailed specification===========================

#1 - Create a resource group, then query the list of resource groups in our subscription
az group create \
    --name "psdemo-rg" \
    --location "centralus"

az group list -o table

#2 - Create virtual network (vnet) and Subnet
az network vnet create \
    --resource-group "psdemo-rg" \
    --name "psdemo-vnet-1" \
    --address-prefix "172.16.0.0/16" \
    --subnet-name "psdemo-subnet-1" \
    --subnet-prefix "172.16.1.0/24"

az network vnet list -o table

#3 - Create public IP address
az network public-ip create \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-1-pip-1"

#4 - Create network security group
az network nsg create \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-nsg-1"

az network nsg list --output table

#5 - Create a virtual network interface and associate with public IP address and NSG
az network nic create \
  --resource-group "psdemo-rg" \
  --name "psdemo-linux-1-nic-1" \
  --vnet-name "psdemo-vnet-1" \
  --subnet "psdemo-subnet-1" \
  --network-security-group "psdemo-linux-nsg-1" \
  --public-ip-address "psdemo-linux-1-pip-1"

az network nic list --output table

#6 - Create a virtual machine
az vm create \
    --resource-group "psdemo-rg" \
    --location "centralus" \
    --name "psdemo-linux-1" \
    --nics "psdemo-linux-1-nic-1" \
    --image "rhel" \
    --admin-username "demoadmin" \
    --authentication-type "ssh" \
    --ssh-key-value ~/.ssh/id_rsa.pub 

az vm create --help | more 

#7 - Open port 22 to allow SSH traffic to host
az vm open-port \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-1" \
    --port "22"

#8 - Grab the public IP of the virtual machine
az vm list-ip-addresses --name "psdemo-linux-1" --output table

#9 - SSH into the new Linux VM
ssh -l demoadmin w.x.y.z

#====================Create a VM with minimal specifications and default settings===================
#1 - Quick and dirty VM creation...this will get placed onto our current vnet/subnet
az vm create \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-1a" \
    --image "UbuntuLTS" \
    --admin-username "demoadmin" \
    --authentication-type "ssh" \
    --ssh-key-value ~/.ssh/id_rsa.pub

#2 - Open 22 for ssh access to the VMs,
az vm open-port \
    --resource-group "psdemo-rg" \
    --name "psdemo-linux-1a" \
    --port "22"

#3 - Grab the public IP of the virtual machine
az vm list-ip-addresses --name "psdemo-linux-1a" --output table

ssh -l demoadmin w.x.y.z