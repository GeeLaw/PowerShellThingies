[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $True)]
    [string]$ScratchDirectory,
    [Parameter(Mandatory = $True)]
    [ScriptBlock]$FailFastTemplate
)

$Error.Clear();
$FailFast = { & $FailFastTemplate 'https://docs.microsoft.com/en-us/sysinternals/downloads/' ($args[0]) 'Please install Sysinternals Suite yourself.'; };

$localPath = [System.IO.Path]::Combine($ScratchDirectory, 'sysinternals.zip');
Remove-Item -LiteralPath $localPath -Force -Recurse -ErrorAction Ignore;

Start-BitsTransfer -Source 'https://download.sysinternals.com/files/SysinternalsSuite.zip' -Destination $localPath -Description 'Download Sysinternals Suite.';
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to download Sysinternals Suite.';
    Return;
}

$dest = [System.Environment]::GetFolderPath('MyDocuments', 'Create');
$dest = [System.IO.Path]::Combine($dest, 'Sysinternals');
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to determine the decompression folder.';
    Return;
}

Expand-Archive -LiteralPath $localPath -DestinationPath $dest -Force;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to expand the archive.';
    Return;
}

Invoke-Item -LiteralPath $dest -ErrorAction Ignore;
