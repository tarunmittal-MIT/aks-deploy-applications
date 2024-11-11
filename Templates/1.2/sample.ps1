# Get the existing resource group or provide your own
$ResourceGroupName = Get-AzResourceGroup | Select-Object -ExpandProperty "ResourceGroupName"
#Container Registry Name: Globally unique, 5-50 characters
$ACRName = "cr76940"
# SKUS: Basic, Standard or Premium - Premium adds private link and geo-replication
$SKU = "Basic"

New-AzContainerRegistry -Name $ACRName -ResourceGroupName $ResourceGroupName -Sku $SKU

New-AzAksCluster -Name myAKSCluster -ResourceGroupName myResourceGroup -GenerateSshKey -AcrNameToAttach $MYACR