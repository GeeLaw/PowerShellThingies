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
$FailFast = { & $FailFastTemplate 'https://nodejs.org/' ($args[0]) 'Please install Node.js yourself.'; };

$candidates = @(Invoke-RestMethod 'https://nodejs.org/dist/index.json' -UseBasicParsing |
    Write-Output |
    Where-Object lts -ne $False |
    ForEach-Object {
        $v = $_.version;
        if ($v.StartsWith('v')) { $v = $v.Substring(1); }
        $_ | Add-Member -MemberType 'NoteProperty' -Name 'version_' -Value ([version]::Parse($v)) -PassThru;
    } | Sort-Object version_ -Descending);
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to retrieve candidates.';
    Return;
}
If ($candidates.Count -eq 0)
{
    & $FailFast 'Failed to find any candidate.';
    Return;
}
$latestLts = $candidates[0];
If (-not ($latestLts.files -Contains 'win-x64-msi'))
{
    & $FailFast 'The latest LTS version does not have an MSI package for 64-bit Windows.';
    Return;
}

$packageUri = 'https://nodejs.org/dist/' + $latestLts.version + '/node-' + $latestLts.version + '-x64.msi';

$localPath = [System.IO.Path]::Combine($ScratchDirectory, 'nodejs.msi');
Remove-Item -LiteralPath $localPath -Force -Recurse -ErrorAction Ignore;

Start-BitsTransfer -Source $packageUri -Destination $localPath -Description 'Download the latest Node.js LTS MSI package for 64-bit Windows.';
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to download the MSI package.';
    Return;
}

$msiExec = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$localPath`" /passive /norestart ALLUSERS=1 ADDLOCAL=ALL" -PassThru;
$msiExec.WaitForExit();
If ($msiExec.ExitCode -ne 0)
{
    & $FailFast 'Failed to install Node.js MSI package.';
    Return;
}
