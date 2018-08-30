#Requires -RunAsAdministrator

[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $True)]
    [string]$ScratchDirectory,
    [Parameter(Mandatory = $True)]
    [ScriptBlock]$FailFastTemplate
)

$Error.Clear();

# Install manually.
# The automation is completely non-trivial since Adobe does not give an interface for that.
& $FailFastTemplate 'https://get.adobe.com/reader/' 'Currently you have to install Adobe Reader DC yourself.' 'Remember to NOT install Chrome-related components in this step.';
