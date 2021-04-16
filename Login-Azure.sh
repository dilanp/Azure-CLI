# Login to Azure and set the correct subscription.
az login
az account show --query name -o tsv
az account set -s "Visual Studio Professional Subscription"
