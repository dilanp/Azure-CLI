#Login to Azure and set the correct subscription.

#Set resource group and ACR variables.
az group list
$resourceGroup = "PluralsightAcr"
az acr list -g $resourceGroup --output table
$registryName = "psacr9577"

#Login to ACR
az acr login -n $registryName

#Get ACR server name
$loginServer = az acr show -n $registryName --query loginServer --output tsv
$loginServer

#Tag the image to be pushed appropriately
docker image ls
docker image tag mvcmovie:v1 psacr9577.azurecr.io/mvcmovie:v1

#Push the image to ACR
docker push psacr9577.azurecr.io/mvcmovie:v1

#Check the ACR repositories
az acr repository list -n $registryName -o table

#Check all tags of a repository
az acr repository show-tags -n $registryName --repository mvcmovie -o table

#Delete a repository (by tag)
az acr repository delete -n $registryName -t samplewebapp:v2