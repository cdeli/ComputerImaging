# OS Image Automation

## Changes

### Version 1.1

-- Adding Parameters for less baked in commands

-- Adding switches for flexibility

### Version 1.0

Initial Commit. All code baked into image.

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