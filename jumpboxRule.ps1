# Define environment variables
$RESOURCE_GROUP = "TFG-Infra"
$NSG_NAME = "nsg-jumpbox"
$RULE_NAME = "Allow-SSH-Jumpbox"
$WAIT_SECONDS = 300  # Time to wait before removing your IP

# Get your public IP automatically
$MY_IP = (Invoke-RestMethod -Uri "https://api.ipify.org?format=text").Trim()

Write-Output " ===== Static IP used: $MY_IP"

# Get current NSG rule config
$ruleJson = az network nsg rule show `
    --resource-group $RESOURCE_GROUP `
    --nsg-name $NSG_NAME `
    --name $RULE_NAME `
    --output json

$rule = $ruleJson | ConvertFrom-Json

# Determine type of source address property
if ($rule.sourceAddressPrefixes) {
    $currentIps = $rule.sourceAddressPrefixes
} elseif ($rule.sourceAddressPrefix) {
    $currentIps = @($rule.sourceAddressPrefix)
} else {
    $currentIps = @()
}

Write-Output " Current IPs in the rule: $($currentIps.Count) addresses configured"

# Add your IP if not present
if ($currentIps -contains $MY_IP) {
    Write-Output " ===== IP $MY_IP is already allowed in rule $RULE_NAME of NSG $NSG_NAME"
} else {
    $newIps = @($currentIps + $MY_IP)

    az network nsg rule update `
        --resource-group $RESOURCE_GROUP `
        --nsg-name $NSG_NAME `
        --name $RULE_NAME `
        --source-address-prefixes $newIps `
        --only-show-errors | Out-Null

    Write-Output " ===== IP $MY_IP added to rule $RULE_NAME in NSG $NSG_NAME"
}

# Wait before removing your IP
Write-Output " ===== Waiting $WAIT_SECONDS seconds before removing the IP"
Start-Sleep -Seconds $WAIT_SECONDS

# Remove only your IP
$filteredIps = $currentIps | Where-Object { $_ -ne $MY_IP }

az network nsg rule update `
    --resource-group $RESOURCE_GROUP `
    --nsg-name $NSG_NAME `
    --name $RULE_NAME `
    --source-address-prefixes $filteredIps `
    --only-show-errors | Out-Null

Write-Output " ===== IP $MY_IP removed from rule $RULE_NAME in NSG $NSG_NAME"
