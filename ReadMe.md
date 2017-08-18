# OS Image Automation

## Changes

### Version 1.2

-- Additional paramters

-- Comments to make parameters more clear

-- General syntax cleanup

### Version 1.1

-- Adding Parameters for less baked in commands

-- Adding switches for flexibility

### Version 1.0

-- Initial Commit. All code baked into image.

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

## Tip o' the hat!

Thank you to Mike Galvin (https://gal.vin) for the initial work on this script. I do not deserve credit for the work behind it. Any and all modifications are my own. The initial script is not.

## Legal

I take no responsibility for any and all negative outcomes of this script. Should issues be caused on a production system, I warn that you test this thoroghly before using it for a production enviroment.