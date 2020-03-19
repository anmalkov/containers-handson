az login

az account show --query name --output json

az account list --query "[].name" --output json
az account set --subscription="Microsoft Azure Internal Consumption"

$rg="container-demo"
$acr="anmcdemo"
$aci="anmcdemo"
$storage="anmcdemo"
$storage_share="anmcdemoshare"


# ACR
# https://docs.microsoft.com/en-us/azure/container-registry/

az group create --name $rg --location westeurope
az acr create --name $acr --resource-group $rg --sku Basic
az acr update --name $acr --admin-enabled true
az acr login --name $acr

$loginServer=(az acr show --name $acr --query loginServer)
$acrPassword=(az acr credential show --name $acr --query passwords[0].value)

docker tag helloworld-api:1.2 $loginServer/helloworld-api:1.2
docker tag helloworld-api:1.2 $loginServer/helloworld-api:latest

docker tag helloworld-web:1.1 $loginServer/helloworld-web:1.1
docker tag helloworld-web:1.1 $loginServer/helloworld-web:latest

docker image ls "*helloworld*"
docker image ls "*/helloworld*"

docker push $loginServer/helloworld-api:1.2
docker push $loginServer/helloworld-api:latest

docker push $loginServer/helloworld-web:1.1
docker push $loginServer/helloworld-web:latest

az acr repository list --name $acr --output table
az acr repository show-tags --name $acr --repository helloworld-api --output table
az acr repository show-tags --name $acr --repository helloworld-web --output table


# ACI
# https://docs.microsoft.com/en-us/azure/container-instances/

az container create --resource-group $rg --name "$aci-api" --image $loginServer/helloworld-api:latest --dns-name-label "$aci-api" --ports 5000 --registry-password $acrPassword --registry-username $acr

$apiUrl="http://$(az container show --resource-group $rg --name "$aci-api" --query 'ipAddress.fqdn' --output tsv):5000/api/products"

az container create --resource-group $rg --name "$aci-web" --image $loginServer/helloworld-web:latest --dns-name-label "$aci-web" --ports 80 --registry-password $acrPassword --registry-username $acr --environment-variables HELLOWORLD_APIURL=$apiUrl

"http://$(az container show --resource-group $rg --name "$aci-web" --query 'ipAddress.fqdn' --output tsv)"

az container logs --resource-group $rg --name "$aci-web"


# multi container
# https://docs.microsoft.com/en-us/azure/container-instances/container-instances-reference-yaml

az container create --resource-group $rg --file aci.yaml
"http://$(az container show --resource-group $rg --name "anmhelloworld" --query 'ipAddress.fqdn' --output tsv)"

az container logs --resource-group $rg --name "anmhelloworld" --container-name "helloworld-web"
az container logs --resource-group $rg --name "anmhelloworld" --container-name "helloworld-api"


# network share
# https://docs.microsoft.com/en-us/azure/container-instances/container-instances-volume-azure-files
az storage account create --resource-group $rg --name $storage --sku Standard_LRS --kind StorageV2
$storage_cs = (az storage account show-connection-string --resource-group $rg --name $storage --query connectionString --output tsv)
$storage_key = (az storage account keys list --resource-group $rg --account-name $storage --query '[0].value' --output tsv)
#$env:AZURE_STORAGE_CONNECTION_STRING = $storage_cs
az storage share create --name $storage_share --connection-string $storage_cs

az container create --resource-group $rg --name "$aci-api-storage" --image $loginServer/helloworld-api:latest --dns-name-label "$aci-api-storage" --ports 5000 --registry-password $acrPassword --registry-username $acr `
    --azure-file-volume-account-name $storage `
    --azure-file-volume-account-key $storage_key `
    --azure-file-volume-share-name $storage_share `
    --azure-file-volume-mount-path "/home"

"http://$(az container show --resource-group $rg --name "$aci-api-storage" --query 'ipAddress.fqdn' --output tsv):5000/api/products"

az container exec --resource-group $rg --name "$aci-api-storage" --exec-command sh
# echo "Initial row added" > /home/readme.md
az storage file list --connection-string $storage_cs --share-name $storage_share --output table


# secrets
# https://docs.microsoft.com/en-us/azure/container-instances/container-instances-volume-secret

az container create --resource-group $rg --name "$aci-api-secrets" --image $loginServer/helloworld-api:latest --dns-name-label "$aci-api-secrets" --ports 5000 --registry-password $acrPassword --registry-username $acr `
    --secrets mysecret1="My first secret" mysecret2="My second secret" `
    --secrets-mount-path "/mnt/secrets"

"http://$(az container show --resource-group $rg --name "$aci-api-secrets" --query 'ipAddress.fqdn' --output tsv):5000/api/products"

az container exec --resource-group $rg --name "$aci-api-secrets" --exec-command sh
#ls /mnt/secrets
#cat /mnt/secrets/mysecret1
#cat /mnt/secrets/mysecret2


# final
az container list --resource-group $rg --query '[].name' --output table
az container delete --resource-group $rg --name "$aci-web"
az container delete --resource-group $rg --name "$aci-api"
az container delete --resource-group $rg --name "anmhelloworld"

az group delete --name $rg
