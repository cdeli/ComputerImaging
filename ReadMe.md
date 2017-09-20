[![Stories in Ready](https://badge.waffle.io/cdeli/ComputerImaging.svg?label=ready&title=Ready)](http://waffle.io/cdeli/ComputerImaging)

# OS Image Automation

Please be sure that you manually add the newly captured image to the task sequence once this completes.

Also the image will hang if you have a window open in Hyper-V watching this, be sure to close the window before the capture completes.

## Special Consideration

Ensure that the variables of: 

$VHDLocal = "\\Contoso-HV\VmBuild"

$VHDRemote = "\\Contoso-HV\VmBuild"

$media = "\\Contoso-HV\VmBuild\TestTouch.iso"

Are in a share with proper access. You will have access permission issues otherwise.

## More Information

This is best run on a schedule.

I am still searching for a way to add the image to a new task sequence once the image is finished.

Currently working on having the XML file be built with PowerShell rather than just adding lines to a backup.
