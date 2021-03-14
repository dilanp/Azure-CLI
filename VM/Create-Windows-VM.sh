
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
    --name "psdemo-win-1-pip-1"

#4 - Create network security group, so we can have seperate security policies
az network nsg create \
    --resource-group "psdemo-rg" \
    --name "psdemo-win-nsg-1"

az network nsg list --output table

#5 - Create a virtual network card and associate with public IP address and NSG
az network nic create \
  --resource-group "psdemo-rg" \
  --name "psdemo-win-1-nic-1" \
  --vnet-name "psdemo-vnet-1" \
  --subnet "psdemo-subnet-1" \
  --network-security-group "psdemo-win-nsg-1" \
  --public-ip-address "psdemo-win-1-pip-1"

az network nic list --output table

#6 - Create a virtual machine
az vm create \
    --resource-group "psdemo-rg" \
    --name "psdemo-win-1" \
    --location "centralus" \
    --nics "psdemo-win-1-nic-1" \
    --image "win2016datacenter" \
    --admin-username "demoadmin" \
    --admin-password "password123412123$%^&*"

az vm create --help | more 

#7 - Open port 3389 to allow RDP traffic to host
az vm open-port \
    --port "3389" \
    --resource-group "psdemo-rg" \
    --name "psdemo-win-1"

#8 - Grab the public IP of the virtual machine
az vm list-ip-addresses --name "psdemo-win-1"  --output table

#9 - Use Remote Desktop to connect to to this VM