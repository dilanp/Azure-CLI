#Create a resource group, then query the list of resource groups in our subscription
az group create \
    --name "psdemo-rg" \
    --location "centralus"

az group list -o table
