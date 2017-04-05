#########################################
# Author: Corey Deli                    #
# Page: https://coreydeli.com           #
# Date: 4/4/2017                        #
# Version: 0.1                          #
#########################################

# Variables

## Location of the "CustomSettings.ini"
$customini = "\\Contoso-svr-MDT\TestBuild$\Control\"

## Possible tasks sequences. Use Task ID's
$tasks = "REFW10-X64-001"#,"NEXT","NEXT" < ADD ADDITIONAL AND REMOVE POUND SIGN FOR MULTIPLE ID's.

## Hyper-V Settings
$hvhost = "Contoso-HV.Contoso.pri"
$VHDLocal = "\\Contoso-HV\VmBuild"
$VHDRemote = "\\Contoso-HV\VmBuild"
$media = "\\Contoso-HV\VmBuild\TestTouch.iso"

## MDT Locations
$mdt = "C:\Program Files\Microsoft Deployment Toolkit\Bin\microsoftdeploymenttoolkit.psd1"
$dplpath = "\\Contoso-svr-MDT\Deployment$"
$capturepath = "\\Contoso-svr-MDT\TestBuild$\Captures"

## Import Hyper-V 2012r2 Modules unless you are running Hyper-V 2016.
Import-Module Hyper-V -RequiredVersion 1.1
## Import Hyper-V 2016 Modules
#Import-Module Hyper-V -RequiredVersion 2

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
Remove-Item $csini\CustomSettings.ini
Move-Item $csini\CustomSettings-backup.ini $csini\CustomSettings.ini
Start-Sleep -s 5
}

## Connect to the MDT Production drive 
New-PsDrive -Name "DS002" -PSProvider FileSystem -Root $dplpath

## Find the files.
$wims = Get-ChildItem $capturepath\*.wim

## Import the reference images into Production
ForEach ($file in $wims) {
    Import-MDTOperatingSystem -Path "DS002:\Operating Systems" -SourceFile $file -DestinationFolder $file.name
}

## Remove the captured images
Remove-Item $capturepath\*.wim