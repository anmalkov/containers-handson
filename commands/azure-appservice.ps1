az login

az account show --query name --output json

az account list --query "[].name" --output json
az account set --subscription="Microsoft Azure Internal Consumption"

$rg="container-demo"
$acr="anmcdemo"
$webapp="anmcdemowa"
$asp="anmcdemo"
$slot="staging"

$loginServer=(az acr show --name $acr --query loginServer)
$acrPassword=(az acr credential show --name $acr --query passwords[0].value)

az acr repository list --name $acr --output table
az acr repository show-tags --name $acr --repository helloworld-api --output table
az acr repository show-tags --name $acr --repository helloworld-web --output table

# App Service Plan

az appservice plan create --name $asp --resource-group $rg --sku S1 --is-linux


# single containers
# https://docs.microsoft.com/en-us/azure/app-service/containers/quickstart-docker

az webapp create --name "$webapp-api" --resource-group $rg --plan $asp --deployment-container-image-name $loginServer/helloworld-api:latest --docker-registry-server-password $acrPassword --docker-registry-server-user $acr
$apiUrl="http://$(az webapp show --name "$webapp-api" --resource-group $rg --query defaultHostName --output tsv)/api/products"
az webapp create --name "$webapp-web" --resource-group $rg --plan $asp --deployment-container-image-name $loginServer/helloworld-web:latest --docker-registry-server-password $acrPassword --docker-registry-server-user $acr
"http://$(az webapp show --name "$webapp-web" --resource-group $rg --query defaultHostName --output tsv)"

az webapp config appsettings set --name "$webapp-web" --resource-group $rg --settings HELLOWORLD_APIURL=$apiUrl

# open portal
# - show configuration (HELLOWORLD_APIURL) 
# - show container settings

# multi-containers
# https://docs.microsoft.com/en-us/azure/app-service/containers/quickstart-multi-container

az webapp create --name "$webapp-multi" --resource-group $rg --plan $asp --multicontainer-config-type compose --multicontainer-config-file appservice-compose.yaml
az webapp config container set --name "$webapp-multi" --resource-group $rg --docker-registry-server-url $loginServer --docker-registry-server-user $acr --docker-registry-server-password $acrPassword
"http://$(az webapp show --name "$webapp-multi" --resource-group $rg --query defaultHostName --output tsv)"

# enable logging
# goto app service logs -> click File System
# https://anmcdemowa-multi.scm.azurewebsites.net/api/logs/docker

# app service scale out
az appservice plan update --name $asp --resource-group $rg --number-of-workers 3

# app service CD
az webapp create --name "$webapp-cicd" --resource-group $rg --plan $asp --multicontainer-config-type compose --multicontainer-config-file appservice-compose.yaml
az webapp config container set --name "$webapp-cicd" --resource-group $rg --docker-registry-server-url $loginServer --docker-registry-server-user $acr --docker-registry-server-password $acrPassword

az webapp deployment slot create --resource-group $rg --name "$webapp-cicd" --slot $slot --configuration-source "$webapp-cicd"
# --configuration-source: Source slot to clone configurations from. Use web app's name to refer to the production slot.

az webapp deployment container config --resource-group $rg --name "$webapp-cicd" --slot $slot --enable-cd true
$cicdUrl=(az webapp deployment container show-cd-url --resource-group $rg --name "$webapp-cicd" --slot $slot --query CI_CD_URL --output tsv)
az acr webhook create --registry $acr --name cdwebhook --actions push --uri $cicdUrl

az webapp deployment slot swap --resource-group $rg --name "$webapp-cicd" --slot $slot --target-slot production