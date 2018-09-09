#Requires -Version 5.0
#Requires -RunAsAdministrator

[CmdletBinding()]
Param()

$Error.Clear();

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
New-Item $scratchDir -ItemType Directory -Force | Invoke-Item -ErrorAction Ignore;
If ($Error.Count -ne 0)
{
    Write-Error 'Failed to create the scratch directory. Cancelled.';
    Return;
}

Write-Verbose "Scratch directory: $scratchDir" -Verbose;

# Automated, must-haves.
.\PerMachine\Install-7Zip.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
.\PerMachine\Install-NodeJs.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
.\PerMachine\Install-GitForWindows.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
.\PerMachine\Install-iTunes.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;

# Automated, optional.
[bool]$dummy = $False
If ($PSCmdlet.ShouldContinue('Do you want to install Image Composite Editor?', 'Optional app', $True, [ref]$dummy, [ref]$dummy))
{
    .\PerMachine\Install-ImageCompositeEditor.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
}

# Not automated.
.\PerMachine\Install-VS2017.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
.\PerMachine\Install-Office365Home.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
.\PerMachine\Install-AdobeReader.ps1 -ScratchDirectory $scratchDir -FailFastTemplate $FFTplt;
