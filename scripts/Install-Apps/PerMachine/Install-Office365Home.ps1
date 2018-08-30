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
# The automation is not possible without making the user sign in.
& $FailFastTemplate 'https://stores.office.com/myaccount/advancedinstalls.aspx' 'Currently you have to install Office 365 Home / Personal yourself.';
