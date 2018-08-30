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
$FailFast = { & $FailFastTemplate 'https://www.apple.com/itunes/download/' ($args[0]) 'Please install iTunes yourself.'; };

$localPath = [System.IO.Path]::Combine($ScratchDirectory, 'itunes.exe');
Remove-Item -LiteralPath $localPath -Force -Recurse -ErrorAction Ignore;

Start-BitsTransfer -Source 'https://www.apple.com/itunes/download/win64' -Destination $localPath -Description 'Download the latest iTunes installer for 64-bit Windows.';
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to download iTunes.';
    Return;
}

$itunesInst = Start-Process -FilePath $localPath -ArgumentList '/passive /norestart' -PassThru;
$itunesInst.WaitForExit();
If ($itunesInst.ExitCode -ne 0)
{
    & $FailFast 'iTunes installer failed.';
    Return;
}
