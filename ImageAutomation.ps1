#########################################
# Author: Corey Deli                    #
# Page: https://coreydeli.com           #
# Date: 8/18/2017                       #
# Version: 1.2                          #
#########################################

# Parameters

Param(
    [parameter(Mandatory=$true)]
    [alias("build")]
    $customini, #This is path to the Customini file. This can be removed from the Parameters and set as a variable should you chose to do so
    
    [parameter(Mandatory=$true)] 
    [alias("DeployPath")] 
    $dplpath, #Path to the Deployment share. Ex. \\ContosoServer\DeploymentShare

    [parameter(Mandatory=$true)]
    [alias("CapturePath")]
    $capturepath, #This is the path where the capture folder lives. Ex. \\ContosoServer\TestShare
    
    [parameter(Mandatory=$true)] 
    [alias("TaskSequence")] 
    $tasks, #Task sequence
    
    [parameter(Mandatory=$true)] 
    [alias("HvHost")] 
    $hvhost, #Name of the Hyper-V host server. This can as well be hard coded.
    
    [parameter(Mandatory=$true)] 
    [alias("vhd")] 
    $VHDLocal, #Location of the VHD on the Hyper-V host.
    
    [parameter(Mandatory=$true)] 
    [alias("boot")] 
    $media, #Path to your ISO for creating the image.

    [parameter(Mandatory=$true)]
    [alias("VnetSwitch")]
    $VnetSwitch,
    
    [alias("Log")] 
    $logpath, #Set this path if you want to create a log.
    
    [alias("SendTo")] 
    $to, 
    
    [alias("SendFrom")] 
    $from, 
    
    [alias("MailServer")] 
    $server, 
    
    [switch]$compat, 
    
    [switch]$remote
)

# Variables

$logfile = ("image-factory{0:yyyy-MM-dd-HH-mm-ss}.log" -f (Get-Date))
$log = "$logpath\$logfile"

$subject = "Image Factory Log File"

## Start Logging
if ($logpath) {
    Start-transcript $log
}

## MDT Locations
#$dplpath = "\\Contoso-svr-MDT\Deployment$"
#$capturepath = "\\Contoso-svr-MDT\TestBuild$\Captures"

## Import Hyper-V 2012r2 Modules. Disable if on 2016
Import-Module -Name Hyper-V -RequiredVersion 1.1
#Import-Module -Name Hyper-V -RequiredVersion 2 # This is the module for Hyper-V 2016
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"

# Actual Running script

ForEach ($id in $tasks) {
 
## Configure the CustomSettings.ini to skip the task sequence and just run.
Copy-Item $customini\CustomSettings.ini $customini\CustomSettings-backup.ini
Start-Sleep -s 5
Add-Content $customini\CustomSettings.ini "TaskSequenceID=$id"
Add-Content $customini\CustomSettings.ini "SkipTaskSequence=YES"
Add-Content $customini\CustomSettings.ini "SkipComputerName=YES"
(Get-Content $customini\CustomSettings.ini).replace('OSDComputerName=%OSDPrefix%-%TaskSequenceID%',';OSDComputerName=%OSDPrefix%-%TaskSequenceID%') | 
    Set-Content $customini\CustomSettings.ini

## Build the VM to create the image on.
$vmname = ("build-{0:yyyy-MM-dd-HH-mm}" -f (get-date))
New-VM -Name $vmname -MemoryStartupBytes 4096MB -BootDevice CD -Generation 1 -NewVHDPath $VHDLocal\$vmname.vhdx -NewVHDSizeBytes 130048MB `
 -SwitchName $VnetSwitch -ComputerName $hvhost
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
$wims = Get-ChildItem $capturepath\Captures\*.wim

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
    send-mailmessages `
        -to $to `
        -from $from `
        -subject $subject `
        -Body $body `
        -smtpserver $server
}