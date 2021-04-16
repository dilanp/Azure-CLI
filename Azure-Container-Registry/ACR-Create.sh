#Login to Azure and set the correct subscription.

#Create variables for resource group and ACR name
resourceGroup="PluralsightAcr"
registryName="psacr$(Get-Random -Minimum 1000 -Maximum 10000)"
location="uksouth"

#Create the resource group
az group create \
    -n $resourceGroup \
    -l $location

#Create the ACR
az acr create \
    -g $resourceGroup \
    -n $registryName \
    --sku Basic \
    --admin-enabled true