#======Create an ACI from an image in ACR. =======

#Login and set the correct Azure subscription.

# Setup required variables.
location="uksouth"
resource_group="AciGhostDemo"
container_group_name="ghost-blog1"

# create a new resource group
az group create \
    -n $resource_group \
    -l $location

# create a docker container using the ghost image from dockerhub
az container create \
    -g resource_group \
    -n $container_group_name \
    --image ghost \
    --ports 2368 \
    --ip-address public \
    --dns-name-label ghostaci

# see details about this container
az container show \
    -g $resource_group \
    -n $container_group_name

# Try out the web site using the URL => "fqdn":"port"
ghostaci.uksouth.azurecontainer.io:2368

# view the logs
az container logs \
    -n $container_group_name \
    -g $resource_group 

# Delete the resource group to clean up everything
az group delete -n $resource_group -y

#======Create an ACI from an image in ACR with a mounted volume. =======

#Login and set the correct Azure subscription.

#Set up required variables
location="uksouth"
resource_group="AciPrivateRegistryDemo"
acr_name="psacr9577"
container_group_name="aci-acr"

login_server=$(az acr show \
-n $acr_name \
--query loginServer \
--output tsv)

acr_password=$(az acr credential show \
-n $acr_name \
--query "passwords[0].value" \
-o tsv)

# create a resource group.
az group create \
-n $resource_group \
-l $location

# create a storage account to
storage_account_name="acishare$RANDOM"

az storage account create \
    -g $resource_group \
    -n $storage_account_name \
    --sku Standard_LRS

# get hold of the connection string of the storage account,
# and export it as an environment variable.
storage_account_connection_string=$(az storage account show-connection-string \
    -n $storage_account_name \
    -g $resource_group \
    --query connectionString \
    -o tsv)

$env:AZURE_STORAGE_CONNECTION_STRING = $storage_account_connection_string

# Create the file share
file_share_name="acishare"
az storage share create -n $file_share_name

storage_key=$(az storage account keys list \
    -g $resource_group \
    --account-name $storage_account_name \
    --query "[0].value" \
    --output tsv)

# see what images are in the registry
az acr repository list -n $acr_name --output table
#Check the tag you want.
az acr repository show-tags \
-n $acr_name \
--repository "mvcmovie" \
-o table

IMAGETAG="$login_server/mvcmovie:v1"

# create a new container group using the image from the private registry
# username used to need to be $login_server, but now seems can be $acr_name
az container create \
    -g $resource_group \
    -n $container_group_name \
    --image $IMAGETAG \
    --cpu 1 \
    --memory 1 \
    --registry-username $acr_name \
    --registry-password $acr_password \
    --azure-file-volume-account-name $storage_account_name \
    --azure-file-volume-account-key $storage_key \
    --azure-file-volume-share-name $file_share_name \
    --azure-file-volume-mount-path "/home" \
    -e TestSetting=FromAzCli2 TestFilelocation=/home/message.txt \
    --dns-name-label "aciacr" \
    --ports 80

# get the site address then, launch in a browser
fqdn=$(az container show \
    -g $resource_group \
    -n $container_group_name \
    --query ipAddress.fqdn \
    -o tsv)
echo "http://$fqdn"

# view the logs for our container
az container logs \
    -n $container_group_name \
    -g $resource_group

# Enter the terminal of the running ACI container.
az container exec \
    -n $container_group_name \
    -g $resource_group \
    --exec-command sh

# Add a file at the mount point path of the container
echo "Hello World!" > /home/message.txt
exit
# Make sure that the file is in the storage account file share.
az storage file list \
    -s $file_share_name \
    -o table

#Refresh the website and notice the text has been read from the file.

# Finally delete the resource group to cleanup the Demo.
az group delete -n $resource_group -y