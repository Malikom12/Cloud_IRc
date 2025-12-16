#!/usr/bin/env pwsh
# teardown.ps1
# this just deletes evrything in ca1_rg by delecting the resource group

Write-Host 'Deleting resource group ca1_rg.'

# this deletes the whole resource group and all the stuff inside it(subnet, vm etc.)
# --yes command means user doesnt need to type yes 
az group delete -n ca1_rg --yes

Write-Host 'Teardown complete, running check now..' -ForegroundColor Green

# check if it actualy got deleted
$rgs = (az group list --query "[?name=='ca1_rg']" | ConvertFrom-Json)
if ( $rgs.length -eq 0 ) {
    Write-Host 'Resource group deleted successfully' -ForegroundColor Green
} else {
    Write-Host 'Resource group still exists, please delete manually.' -ForegroundColor Red
}