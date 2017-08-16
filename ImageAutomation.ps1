#########################################
# Author: Corey Deli                    #
# Page: https://coreydeli.com           #
# Date: 4/4/2017                        #
# Version: 1.1                          #
#########################################

# Parameters

Param(
    [parameter(Mandatory=$true)]
    [alias("build")]
    $customini,
    
    [parameter(Mandatory=$true)] 
    [alias("deploy")] 
    $dplpath, 
    
    [parameter(Mandatory=$true)] 
    [alias("ts")] 
    $tasks, 
    
    [parameter(Mandatory=$true)] 
    [alias("hv")] 
    $hvhost, 
    
    [parameter(Mandatory=$true)] 
    [alias("vhd")] 
    $VHDLocal, 
    
    [parameter(Mandatory=$true)] 
    [alias("boot")] 
    $media, 
    
    #[parameter(Mandatory=$true)] 
    #[alias("vnic")] 
    #$vmnic, 
    
    [alias("l")] 
    $logpath, 
    
    [alias("sendto")] 
    $to, 
    
    [alias("from")] 
    $from, 
    
    [alias("mail")] 
    $server, 
    
    [switch]$compat, 
    
    [switch]$remote
)

# Variables

#Log File

$logfile = ("image-factory{0:yyyy-MM-dd-HH-mm-ss}.log" -f (Get-Date))
$log = "$logpath\$logfile"

$subject = "Image Factory Log File"

## Start Logging
if ($logpath) {
    Start-transcript $log
}

## Location of the "CustomSettings.ini"
#$customini = "\\Contoso-svr-MDT\TestBuild$\Control\"

## Possible tasks sequences. Use Task ID's
#$tasks = "REFW10-X64-001"#,"NEXT","NEXT" < ADD ADDITIONAL AND REMOVE POUND SIGN FOR MULTIPLE ID's.

## Hyper-V Settings
#$hvhost = "Contoso-HV.Contoso.pri"
#$VHDLocal = "\\Contoso-HV\VmBuild"
#$VHDRemote = "\\Contoso-HV\VmBuild"
#$media = "\\Contoso-HV\VmBuild\TestTouch.iso"

## MDT Locations
$dplpath = "\\Contoso-svr-MDT\Deployment$"
$capturepath = "\\Contoso-svr-MDT\TestBuild$\Captures"

## Import Hyper-V 2012r2 Modules. Disable if on 2016
Import-Module Hyper-V -RequiredVersion 1.1
#Import-Module Hyper-V -RequiredVersion 2 # This is the module for Hyper-V 2016
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

# Actual script running

ForEach ($id in $tasks) {
 
## Configure the CustomSettings.ini to skip the task sequence and just run.
Copy-Item $customini\CustomSettings.ini $customini\CustomSettings-backup.ini
Start-Sleep -s 5
Add-Content $customini\CustomSettings.ini "TaskSequenceID=$id"
Add-Content $customini\CustomSettings.ini "SkipTaskSequence=YES"
Add-Content $customini\CustomSettings.ini "SkipComputerName=YES"
(Get-Content $customini\CustomSettings.ini).replace('OSDComputerName=%OSDPrefix%-%TaskSequenceID%',';OSDComputerName=%OSDPrefix%-%TaskSequenceID%') | `
    Set-Content $customini\CustomSettings.ini

## Build the VM to create the image on.
$vmname = ("build-{0:yyyy-MM-dd-HH-mm}" -f (get-date))
New-VM -Name $vmname -MemoryStartupBytes 4096MB -BootDevice CD -Generation 1 -NewVHDPath $VHDLocal\$vmname.vhdx -NewVHDSizeBytes 130048MB `
    -SwitchName "Microsoft Network Adapter Multiplexor Driver - Virtual Switch" -ComputerName $hvhost
Set-VM $vmname -ProcessorCount 2 -StaticMemory -ComputerName $hvhost
Set-VMDvdDrive -VMName $vmname -ControllerNumber 1 -ControllerLocation 0 -Path $media -ComputerName $hvhost
Start-VM $vmname -ComputerName $hvhost
 
## Wait for the VM to enter a "Stopped" State
while ((get-vm -name $vmname -ComputerName $hvhost).state -ne 'Off') { start-sleep -s 5 }
 
## Remove the VM and all VM files associated
Remove-VM $vmname -ComputerName $hvhost -Force
Remove-Item $VHDRemote\$vmname.vhdx

## Reset MDT Custom Settings
Remove-Item $customini\CustomSettings.ini -Force
Move-Item $customini\CustomSettings-backup.ini $customini\CustomSettings.ini
Start-Sleep -s 5
}

## Connect to the MDT Production drive 
New-PsDrive -Name "DS002" -PSProvider MDTProvider -Root $dplpath -verbos

## Find the files.
$wims = Get-ChildItem $capturepath\*.wim

## Import the reference images into Production
ForEach ($file in $wims) {
    Import-MDTOperatingSystem -Path "DS002:\Operating Systems" -SourceFile $file -DestinationFolder $file.name -Move
}

## Cleanup Stage
Remove-PSDrive -Name "DS002"

## Stop logging
if ($logpath) {
    stop-transcript
}

# Email Report
if ($server) {
    $body = Get-Content -Path $log | out-string 
    send-mailmessages -to $to -from $from -subject $subject -Body $body -smtpserver $server
}