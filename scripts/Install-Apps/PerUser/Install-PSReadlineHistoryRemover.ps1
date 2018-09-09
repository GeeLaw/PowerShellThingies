[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $True)]
    [string]$ScratchDirectory,
    [Parameter(Mandatory = $True)]
    [ScriptBlock]$FailFastTemplate
)

$Error.Clear();
$FailFast = {
    & $FailFastTemplate $PSScriptRoot ($args[0]) 'Please install PSReadline History Remover yourself by copying it from PerUser directory to Startup.';
};

$localPath = [System.Environment]::GetFolderPath('Startup', 'Create');
$localPath = [System.IO.Path]::Combine($localPath, 'Remove-PSReadlineHistory.vbs');
Remove-Item -LiteralPath $localPath -Force -Recurse -ErrorAction Ignore;

$asset = [System.IO.Path]::Combine($PSScriptRoot, 'Remove-PSReadlineHistory.vbs.dat');

Copy-Item -LiteralPath $asset -Destination $localPath -Force;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to copy the file to Startup.';
    Return;
}
