#!/usr/bin/env pwsh
# setup.ps1 - this creates all the stuff for the irc server

# Initaialised variables
$ResourceGroup = "ca1_rg"
$Location = "northeurope"
$VNetName = "ca1-vnet"
$SubnetName = "ca1-subnet"
$VmName = "ca1-irc-server"
$AdminUser = "developer"

# first a check to see if the resource group already exists
# if resource group exists allows to automatically run teardown else a message is returned saying run teardown.
Write-Host 'Checking for existing resource group'
$rgs = (az group list --query "[?name=='ca1_rg']" | ConvertFrom-Json)
if ( $rgs.length -gt 0 ) {
    Write-Host "Resource group 'ca1_rg' already exists." -ForegroundColor Red
    $answer = Read-Host "Do you want to run teardown.ps1 to delete it? (y/n)"
    if ( $answer -eq "y" -or $answer -eq "Y" ) {
        Write-Host 'Running teardown!'
        ./teardown.ps1
        Write-Host 'Waiting for deletion to complete.'
        Start-Sleep -Seconds 30
    } else {
        Throw "Setup cancelled. Resource group already exists, please run teardonw first."
    }
}


# then create the resource group
Write-Host 'Creating resource group'
az group create -n $ResourceGroup -l $Location

# Then creat vnet and subnet 
Write-Host 'Creating VNet and Subnet'
az network vnet create -n $VNetName --resource-group $ResourceGroup --address-prefix 10.0.0.0/16 --subnet-name $SubnetName --subnet-prefixes 10.0.0.0/24

# create the vm with cloud init
Write-Host 'Creating Linux VM'
az vm create `
    --resource-group $ResourceGroup `
    --name $VmName `
    --image Ubuntu2204 `
    --size Standard_B1s `
    --admin-username $AdminUser `
    --generate-ssh-keys `
    --vnet-name $VNetName `
    --subnet $SubnetName `
    --custom-data vm_init.yml `
    --public-ip-sku Standard

# open port 6667 for irc connections
Write-Host 'Opening port 6667 for IRC'
az vm open-port --resource-group $ResourceGroup --name $VmName --port 6667 --priority 1001

# using port 80 for the web dashboard
Write-Host 'Opening port 80 for Web Dashboard'
az vm open-port --resource-group $ResourceGroup --name $VmName --port 80 --priority 1002
#the priority flag just allows you to give priority or order in which rule is created, if you do not give an order they crash. Reason for setting it to 1001 and 1002 is because ssh is set to 1000 by default

# get the ip address to know where to connect
$ip = az vm show -d -g $ResourceGroup -n $VmName --query publicIps -o tsv
Write-Host 'Setup complete' -ForegroundColor Green
Write-Host "VM Public IP: $ip"
Write-Host "Web Dashboard: http://$ip"