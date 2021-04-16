#Login and set the correct Azure subscription.

# setup the variables.
acr_resource_group="PluralsightAcr"
resource_group="cicdappservice"
location="uksouth"
plan_name="cicdappservice"
app_name="cicd-pluralsight-1"
subscription_id=$(az account show --query id --output tsv)

az acr list \
    -g $acr_resource_group \
    --output table

acr_name="psacr9577" #Need to set manually using the result of the query above.

#Use the following information to form the ACR image name.
acr_login_server=$(az acr show \
    -n $acr_name \
    --query loginServer \
    -o tsv)
az acr repository list -n $acr_name -o table
image="mvcmovie"
az acr repository show-tags -n $acr_name --repository mvcmovie -o table #Get repo name from query above.
tag="v1"
image_name="$acr_login_server/$image:$tag"

#Use these only if you need ACR credentials!!!
#cr_username=$(az acr credential show \
#   -n $acr_name \
#   --query username \
#   -o tsv)
#cr_password=$(az acr credential show \
#   -n $acr_name \
#   --query passwords[0].value \
#   -o tsv)

# create a resource group.
az group create \
    -l $location \
    -n $resource_group

# create an app service plan to host
az appservice plan create \
    -n $plan_name \
    -g $resource_group \
    -l $location \
    --sku S1 \
    --is-linux

# n.b. can't use anything but docker hub here
# so we have to arbitrarily pick a runtime --runtime "node|6.2" or a public image like scratch.
az webapp create \
    -n $app_name \
    -g $resource_group \
    --plan $plan_name \
    --deployment-container-image-name $image_name

#set the WEBSITES_PORT environment variable.
az webapp config appsettings set \
    -g $resource_group \
    -n $app_name \
    --settings WEBSITES_PORT=80

#Enable managed identity for the web app and get the principalId.
principal_id=$(az webapp identity assign \
    -g $resource_group \
    -n $app_name \
    --query principalId \
    --output tsv)

#Grant the web app permission to access the container registry.
az role assignment create \
    --assignee $principal_id \
    --scope "/subscriptions/$subscription_id/resourceGroups/$acr_resource_group/providers/Microsoft.ContainerRegistry/registries/$acr_name" \
    --role "AcrPull"

# specify the container registry and the image to deploy for the web app.
az webapp config container set \
    -n $app_name \
    -g $resource_group \
    --docker-custom-image-name $acr_login_server/$image:$tag \
    --docker-registry-server-url "https://$acr_login_server"

#Now try the website URL!!!
echo "http://$app_name.azurewebsites.net"

# create a staging slot by cloning from production slot settings.
az webapp deployment slot create \
    -g $resource_group \
    -n $app_name \
    -s staging \
    --configuration-source $app_name

# Notice that staging has -staging added in the host name.
# This should now be running an exact copy of the production slot.
az webapp show \
    -n $app_name \
    -g $resource_group \
    -s staging \
    --query "defaultHostName" \
    -o tsv

# enable CD for the staging slot
az webapp deployment container config \
    -g $resource_group \
    -n $app_name \
    -s staging \
    --enable-cd true

# get the webhook URL for staging slot.
ci_cd_url=$(az webapp deployment container show-cd-url \
    -s staging \
    -n $app_name \
    -g $resource_group \
    --query CI_CD_URL \
    -o tsv)

# Configure the webhook on an ACR registry
az acr webhook create \
    --registry $acr_name \
    -n myacrwebhook \
    --actions push \
    --uri $ci_cd_url

# Change the code to make the website different.
# Do another docker build and push a new version to ACR.
az acr login -n $acr_name
docker push pluralsightacr.azurecr.io/samplewebapp:latest

# perform a slot swap
az webapp deployment slot swap \
    -g $resource_group \
    -n $app_name \
    --slot staging \
    --target-slot production

# clean up the web app and app service.
az group delete -n $resource_group --yes --no-wait
# delete the webhook
az acr webhook delete --registry $acr_name --name myacrwebhook