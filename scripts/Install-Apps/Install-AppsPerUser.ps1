#Requires -Version 5.0

[CmdletBinding()]
Param()

$Error.Clear();

# Advise user to not run as administrator

$currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = [System.Security.Principal.WindowsPrincipal]::new($currentIdentity)
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
If ($currentPrincipal.IsInRole($adminRole))
{
    Write-Warning 'You are running as administrator. It is advisable to run Install-AppsPerUser.ps1 unelevated.' -WarningAction Continue;
    [bool]$dummy = $False;
    If (-not $PSCmdlet.ShouldContinue('Do you wish to stop?', 'Confirm', $True, [ref]$dummy, [ref]$dummy))
    {
        Return;
    }
}

# Prologue

[System.Net.ServicePointManager]::SecurityProtocol = 'Ssl3, Tls, Tls11, Tls12';

$FFTplt = {
    Start-Process ($args[0]);
    $args | Select-Object -Skip 1 | Write-Host -BackgroundColor Black -ForegroundColor Red;
    Pause;
    $Error.Clear();
}

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force;

If ($Error.Count -ne 0)
{
    Write-Error 'One or more errors occurred before any installation. Cancelled.';
    Return;
}

# Create and open scratch directory for inspection.
$scratchDir = [System.IO.Path]::GetTempFileName();
If ($Error.Count -ne 0)
{
    Write-Error 'Failed to find a scratch directory. Cancelled.';
    Return;
}
Remove-Item -LiteralPath $scratchDir -Force -Recurse -ErrorAction Ignore;
New-Item $scratchDir -ItemType Directory -Force | Invoke-Item;
If ($Error.Count -ne 0)
{
    Write-Error 'Failed to create the scratch directory. Cancelled.';
    Return;
}

# Automated, must-haves.
.\PerUser\Install-MiKTeX.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
.\PerUser\Install-VSCode.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
.\PerUser\Install-ILSpy.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;

# Not automated.
.\PerUser\Install-SourceTree.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
