[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $True)]
    [string]$ScratchDirectory,
    [Parameter(Mandatory = $True)]
    [ScriptBlock]$FailFastTemplate
)

$Error.Clear();
$FailFast = { & $FailFastTemplate 'https://code.visualstudio.com/' ($args[0]) 'Please install Visual Studio Code yourself.'; };

$localPath = [System.IO.Path]::Combine($ScratchDirectory, 'vsc-x64.exe');
Remove-Item -LiteralPath $localPath -Force -Recurse -ErrorAction Ignore;

Start-BitsTransfer -Source 'https://aka.ms/win32-x64-user-stable' -Destination $localPath -Description 'Download the latest Visual Studio Code Installer (x64, per-user, Windows).';
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to download the latest stable x64 release for Windows.';
    Return;
}

$instArg = '/SP- /SILENT /NOCANCEL /NORESTART /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS';
$instArg += ' /LANG=english /DIR="expand:{userpf}{\}VSCode"';
$instArg += ' /MERGETASKS="desktopicon,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath,!runcode"';
$instProc = Start-Process -FilePath $localPath -ArgumentList $instArg -PassThru;
$instProc.WaitForExit();
If ($instProc.ExitCode -ne 0)
{
    & $FailFast 'Visual Studio Code Installer failed.';
    Return;
}

Write-Verbose 'Setting Git default editor to Visual Studio Code...' -Verbose;
Start-Process -FilePath 'git.exe' -ArgumentList 'config --global --unset-all core.editor' -NoNewWindow -Wait -ErrorAction SilentlyContinue;
Start-Process -FilePath 'git.exe' -ArgumentList 'config --global --add core.editor "code --wait"' -NoNewWindow -Wait -ErrorAction SilentlyContinue;
If ($Error.Count -ne 0)
{
    Write-Warning 'Failed to set Git default editor to Visual Studio Code.' -WarningAction Continue;
    $Error.Clear();
}
Else
{
    Write-Verbose 'Successfully set Git default editor to Visual Studio Code.' -Verbose;
}
