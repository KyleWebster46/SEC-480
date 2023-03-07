function 480Banner(){
    Write-Host "
__/\\\\\\\\\\\\\_______/\\\\\\\\\_____/\\\\\\\\\\\__/\\\\\_____/\\\_        
 _\/\\\/////////\\\___/\\\\\\\\\\\\\__\/////\\\///__\/\\\\\\___\/\\\_       
  _\/\\\_______\/\\\__/\\\/////////\\\_____\/\\\_____\/\\\/\\\__\/\\\_      
   _\/\\\\\\\\\\\\\/__\/\\\_______\/\\\_____\/\\\_____\/\\\//\\\_\/\\\_     
    _\/\\\/////////____\/\\\\\\\\\\\\\\\_____\/\\\_____\/\\\\//\\\\/\\\_    
     _\/\\\_____________\/\\\/////////\\\_____\/\\\_____\/\\\_\//\\\/\\\_   
      _\/\\\_____________\/\\\_______\/\\\_____\/\\\_____\/\\\__\//\\\\\\_  
       _\/\\\_____________\/\\\_______\/\\\__/\\\\\\\\\\\_\/\\\___\//\\\\\_ 
        _\///______________\///________\///__\///////////__\///_____\/////__
        "
}

function 480Connect([string] $server){
    $conn = $global:DefaultVIServer

    if ($conn){
        $msg = "Already Connected to: {0}" -f $conn
        Write-Host -ForegroundColor Green $msg
    }
    else{
        $conn = Connect-VIServer -Server $server
    }
}
function UIMENU($config){
    Write-Host "
    Pick one of the following:
    [1] Linked clone
    [2] Base clone
    [3] Cancel
    [4] PowerState
    [5] Network Configs
    [6] Set Network Addapters
    [7] Network Info
    "
    $menuoption = Read-Host

    switch($menuoption){
        '1' {ClonelinkVM($config)}
        '2' {BaseClone($config)}
        '3' {Clear-Host Exit}
        '4' {Power($config)}
        '5' {New-Network($config)}
        '6' {Set-Network($config)}
        '7' {Get-IP($config)}
        default {Write-Host "Please select an option 1-4"}

    }

}
function Get-480Config([string] $config_path) {
    Write-Host "Reading" $config_path
    $conf=$null

    if(Test-Path $config_path){
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = "Using config at {0}" -f $config_path
        Write-Host -ForegroundColor "Green" $msg
    }
    else{
        Write-Host -ForegroundColor "Red" "No Configuration"
    }
    return $conf
}
function Select-VM([string] $folder) {
    $selected_vm=$null
    try{
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms){
            Write-Host [$index] $vm.Name
            $index+=1
        }
        $pick_index = Read-Host "which index number [x] are you picking?"
        $selected_vm = $vms[$pick_index -1]
        Write-Host "you picked" $selected_vm.Name
        return $selected_vm
   
    }
    catch{
        Write-Host "Invalid folder: $folder"
    }
}
function ClonelinkVM($config) {
    # Reads host if you want to use a diffrent folder
    $folderselect = Read-Host -Prompt "The default folder is BASEVM. Leave blank for default"
    # If the option is left blank, will use the default from .json
    if ($folderselect -eq ""){
        $vm = Select-VM -folder $config.vm_folder
        # If not left blank, will use what the user typed
    }else{
        $vm = Select-VM -folder $folderselect
    }
    # $snapshot = Get-Snapshot -VM $vm1 -Name $conf.snapshot
    # $vmhost = Get-VMHost -Name "192.168.7.28"
    # $ds = Get-Datastore -Name Datastore2-super18
    # Following code from older script
    $Namingvm = Read-Host -Prompt "Enter what you wish to name the VM"
    $linkedname = $Namingvm
    # Actually creates linked clone
    $linkedvm = New-VM -LinkedClone -Name $linkedname -VM $vm -ReferenceSnapshot $config.snapshot -VMHost $config.esxi_host -Datastore $config.datastore
    $linkedvm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $config.default_network
}
function BaseClone($config) {
    # Reads host if you want to use a diffrent folder
    $folderselect = Read-Host -Prompt "The default folder is BASEVM. Leave blank for default"
    # If the option is left blank, will use the default from .json
    if ($folderselect -eq ""){
        $vm = Select-VM -folder $config.vm_folder
        # If not left blank, will use what the user typed
    }else{
        $vm = Select-VM -folder $folderselect
    }

    $linkedname = "{0}.linked" -f $vm.name
    $linkedvm = New-VM -LinkedClone -Name $linkedName -VM $vm -ReferenceSnapshot $config.snapshot -VMHost $congif.esxi_host -Datastore $config.datastore
    $newvm = New-VM -Name "$vm.v3" -VM $linkedvm -VMHost $config.esxi_host -Datastore $config.datastore
    $newvm | new-snapshot -Name "base"
    $linkedvm | Remove-VM
}
function Power($config){
    $selected_vm=$null
    try{
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms){
            Write-Host [$index] $vm.Name
            $index+=1
        }
        $pick_index = Read-Host "which index number [x] are you picking?"
        $selected_vm = $vms[$pick_index -1]
        Write-Host "you picked" $selected_vm.Name
   
    }
    catch{
        Write-Host "Invalid folder: $folder"
    }
    # powerstate variable
    $powerstate = Read-Host -Prompt "Powervm on or off"
    #checks powerstate variable
    if($powerstate -eq "on"){
        # starts VM
        Start-VM -VM $selected_vm -Confirm:$true -RunAsync
        # If its set to off
    }elseif ($powerstate -eq "off"){
        #Turns VM off
        Stop-VM -VM $selected_vm -Confirm:$true
    }
}
function New-Network($cofnig){
    # Creates new Virtual Switch
    $vswitch = New-VirtualSwitch -VMHost $config.esxi_host -Name (Read-Host -Prompt "Please enter name for new Vswitch")
    # Creates a new port group
    New-VirtualPortGroup -VirtualSwitch $vswitch -Name (Read-Host -Prompt "Please etner the name of the new Port Group")
    
    Get-VirtualSwitch
    Get-VirtualPortGroup


}
function Get-IP($config){
    $vmpick = Read-Host -Prompt "Enter the vm name"

    $mac = Get-NetworkAdapter -VM $vmpick | Select-Object MacAddress
    $ip = (Get-VM -Name $vmpick).Guest.IPAddress[0]

    Write-Host "Ip address is:" $ip
    Write-Host "Mac address is: " $mac
    # Gets the MAc address
    # Get-VM $vmname | Get-NetworkAdapter | Select MacAddress
    # Gets IP address
    # (Get-VM -Name $vmname).Guest.IPAddress[0]
    
    # Get-VM | Select $vmname, @{N="IP Address";E={@($_.guest.IPAddress[0])}}
}
function Set-Network($config){
    $selected_vm=$null
    try{
        $vms = Get-VM -Location $folder
        $index = 1
        foreach($vm in $vms){
            Write-Host [$index] $vm.Name
            $index+=1
        }
        $pick_index = Read-Host "which index number [x] are you picking?"
        $selected_vm = $vms[$pick_index -1]
        Write-Host "you picked" $selected_vm.Name
   
    }
    catch{
        Write-Host "Invalid folder: $folder"
    }
    
    $Nameofnetwork = Read-Host -Prompt "Please enter the name of a network"

    Get-VM -Name $selected_vm | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $Nameofnetwork
}