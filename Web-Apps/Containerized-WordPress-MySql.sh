#Login and set the correct Azure subscription.

# Set variables to be used
resource_group="wordpressappservice"
location="uksouth"
plan_name="wordpressappservice"
mysql_server_name="mysql-wp-db-$RANDOM"
admin_user="wpadmin"
admin_password="P@ssw0rd789%^9&£"
app_name="wordpress-$RANDOM"
docker_repo="wordpress" # https://hub.docker.com/r/_/wordpress/

# create a resource group.
az group create \
    -l $location \
    -n $resource_group

# create an app service plan for hosting.
az appservice plan create \
    -n $plan_name \
    -g $resource_group \
    -l $location \
    --sku S1 \
    --is-linux
    
# create a MySql database
# https://docs.microsoft.com/en-us/azure/mysql/quickstart-create-mysql-server-database-using-azure-cli
# supported mysql versions: https://docs.microsoft.com/en-us/azure/mysql/concepts-supported-versions
# this wordpress demo also requires SSL enforcement to be disabled
az mysql server create \
    -g $resource_group \
    -n $mysql_server_name \
    -l $location \
    --sku-name GP_Gen5_2 \
    --version 5.7 \
    --admin-user $admin_user \
    --admin-password $admin_password \
    --ssl-enforcement Disabled
             

# open the firewall (use 0.0.0.0 to allow all Azure traffic for now)
az mysql server firewall-rule create \
    -g $resource_group \
    --server $mysql_server_name \
    --name AllowAppService \
    --start-ip-address 0.0.0.0 \
    --end-ip-address 0.0.0.0

# create a new webapp based on our DockerHub image
az webapp create \
    -n $app_name \
    -g $resource_group \
    --plan $plan_name \
    -i $docker_repo

# configure wordpress database settings.
wordpress_db_host=$(az mysql server show \
    -g $resource_group \
    -n $mysql_server_name \
    --query "fullyQualifiedDomainName" \
    -o tsv)

az webapp config appsettings set \
    -n $app_name \
    -g $resource_group \
    --settings \
        WORDPRESS_DB_HOST=$wordpress_db_host \
        WORDPRESS_DB_USER="$admin_user@$mysql_server_name" \
        WORDPRESS_DB_PASSWORD="$admin_password"

# launch in a browser
site=$(az webapp show \
    -n $app_name \
    -g $resource_group \
    --query "defaultHostName" \
    -o tsv)
echo https://$site

# scale up app service
az appservice plan update \
    -n $plan_name \
    -g $resource_group \
    --number-of-workers 3

# clean up by disposing the resourec group
az group delete \
    --name $resource_group \
    --yes \
    --no-wait