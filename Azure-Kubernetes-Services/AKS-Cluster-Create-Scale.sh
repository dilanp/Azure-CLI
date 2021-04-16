# Login to Azure and set the correct subscription.

# Setup all required variables.
resource_group="K8s"
location="uksouth"
cluster_name="MyTestCluster"
node_count=1

# Create the resource group.
az group create \
    -n $resource_group \
    -l $location

# Create the K8s cluster and check it...
az aks create \
    -g $resource_group \
    -n $cluster_name \
    --node-count $node_count \
    --generate-ssh-keys

az aks show \
    -g $resource_group \
    -n $cluster_name

# check we have kubectl (installed as part of docker desktop).
kubectl version --short
# If not installed then install it with,
# az aks install-cli

# Get credentials and set up the context for kubectl to use.
az aks get-credentials \
    -g $resource_group \
    -n $cluster_name

# Check we're connected.
kubectl get nodes

# Deploy the app.
kubectl apply -f sample-app.yaml

# Find out where it is
kubectl get service samplewebapp --watch

# Launch app in browser (use IP address from previous command)
Start-Process http://IPAddress:Port

# See the status of our pods
kubectl get pod

# View logs from a pod
kubectl logs pod_name

# Scale the cluster
az aks scale \
    -g $resource_group \
    -n $cluster_name \
    --node-count 3

# See the nodes
kubectl get nodes

# deploy the example vote app
# https://github.com/dockersamples/example-voting-app
kubectl apply -f example-vote.yml

# watch for the public ip addresses of the vote and result services
kubectl get service --watch

# change the vote deployment to 3 replicas with eggs and bacon
kubectl apply -f example-vote-v2.yml

# run kubernetes dashboard
az aks browse \
    -g $resource_group \
    -n $cluster_name

# n.b. if the dashboard shows errors, you may need this fix:
# https://pascalnaber.wordpress.com/2018/06/17/access-dashboard-on-aks-with-rbac-enabled/
kubectl create clusterrolebinding kubernetes-dashboard \
    -n kube-system \
    --clusterrole=cluster-admin \
    --serviceaccount=kube-system:kubernetes-dashboard

# Directly scale to three replicas of our front end container
kubectl scale \
    --replicas=3 \
    deployment/samplewebapp

# Upgrade a container directly
kubectl set image deployment samplewebapp samplewebapp=markheath/samplewebapp:v2

# Delete an app deployed with kubectl apply
kubectl delete -f example-vote-v2.yml

# deploy a second instance to another namespace
kubectl create namespace staging

kubectl apply -f example-vote.yml -n staging
kubectl get service -n staging

# Clean up
az group delete \
    -n $resource_group \
    --yes \
    --no-wait

