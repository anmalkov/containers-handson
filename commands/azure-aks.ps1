az login

az account show --query name --output json

az account list --query "[].name" --output json
az account set --subscription="<subscription name>"

$rg="container-demo"
$acr="anmcdemo"
$aks="anmcdemo"

$loginServer=(az acr show --name $acr --query loginServer)
$acrPassword=(az acr credential show --name $acr --query passwords[0].value)

az acr repository list --name $acr --output table
az acr repository show-tags --name $acr --repository helloworld-api --output table
az acr repository show-tags --name $acr --repository helloworld-web --output table

# AKS

az aks create --resource-group $rg --name $aks --node-count 1 --generate-ssh-keys --attach-acr $acr
az aks update --resource-group $rg --name $aks --attach-acr $acr


kubectl get nodes

kubectl apply -f aks.yaml

kubectl get services
kubectl get service web --watch

kubectl get deployments

kubectl get pods

kubectl logs <podName>


# scaling
az aks scale --resource-group $rg --name $aks --node-count 3
kubectl get nodes
# change number of replicas for api in YAML
kubectl apply -f aks.yaml
kubectl get pods


# dashboard
kubectl create clusterrolebinding kubernetes-dashboard -n kube-system --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
az aks browse --resource-group $rg --name $aks
