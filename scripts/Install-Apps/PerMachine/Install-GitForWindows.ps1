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
$FailFast = { & $FailFastTemplate 'https://gitforwindows.org/' ($args[0]) 'Please install Git for Windows yourself.'; };

$response = Invoke-WebRequest 'https://git-scm.com/download/win' -UseBasicParsing;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to retrieve downloads page.';
    Return;
}

$candidates = @($response.Links | Where-Object outerHTML -like "*href=*.exe*>*64*bit*windows*setup*</*");
If ($candidates.Count -ne 1)
{
    & $FailFast 'Failed to find the only candidate for 64-bit Windows installation.';
    Return;
}

$exeUri = [uri]::new($response.BaseResponse.ResponseUri, $candidates[0].href).AbsoluteUri.ToString();
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to compose URI.';
    Return;
}

$localPath = [System.IO.Path]::Combine($ScratchDirectory, 'gitforwindows.exe');
Remove-Item -LiteralPath $localPath -Force -Recurse -ErrorAction Ignore;

Write-Verbose 'Downloading Git for Windows Installer (x64)...' -Verbose;
[System.Net.WebClient]::new().DownloadFile($exeUri, $localPath);
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to download Git for Windows Installer (x64).';
    Return;
}
Write-Verbose 'Finished downloading.' -Verbose;

$infPath = [System.IO.Path]::Combine($ScratchDirectory, 'gitinst.inf');
$infContent = @(
    '[Setup]',
    'NoIcons=0',
    'Components=icons,icons\desktop,ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh,autoupdate',
    'EditorOption=VIM',
    'PathOption=Cmd',
    'SSHOption=OpenSSH',
    'CURLOption=WinSSL',
    'CRLFOption=CRLFCommitAsIs',
    'BashTerminalOption=MinTTY',
    'PerformanceTweaksFSCache=Enabled',
    'UseCredentialManager=Enabled',
    'EnableSymlinks=Disabled',
    ''
) -join "`r`n";
[System.IO.File]::WriteAllText($infPath, $infContent);
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to write unattended answer file.';
    Return;
}

$instArg = '/SP- /SILENT /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /LOADINF="'
$instArg += $infPath + '"'

$instProc = Start-Process -FilePath $localPath -ArgumentList $instArg -PassThru;
$instProc.WaitForExit();
If ($instProc.ExitCode -ne 0)
{
    & $FailFast 'Git for Windows Installer failed.';
    Return;
}
