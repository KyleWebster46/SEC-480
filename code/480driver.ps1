Import-Module '480-utils' -Force
#call banner function
480Banner
$conf = Get-480Config -config_path "480.json"
480Connect -server $conf.vcenter_server
UIMENU($conf)
# Write-Host "What folder do you wish to select from, BASEVM or PROD?"
# $selectionfolder = Read-Host
# Select-VM -folder $selectionfolder
