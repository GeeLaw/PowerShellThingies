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
# The automation is quite complicated and the process can take long.
# Also, the effort might not be worth it since VS getting an update soon.
& $FailFastTemplate 'https://visualstudio.microsoft.com/downloads/' 'Currently you have to install Visual Studio 2017 yourself.';
