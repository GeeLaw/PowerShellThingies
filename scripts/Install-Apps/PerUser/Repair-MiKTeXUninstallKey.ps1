[CmdletBinding()]
Param()

$Error.Clear();

If (-not $PSBoundParameters.ContainsKey('ErrorAction'))
{
    $local:ErrorActionPreference = 'Stop';
}

$localAppDataFolder = [System.Environment]::GetFolderPath('LocalApplicationData', 'Create');
$installFolder = [System.IO.Path]::Combine($localAppDataFolder, 'Programs', 'MiKTeX');
$dataFolder = [System.IO.Path]::Combine($localAppDataFolder, 'MiKTeX', 'Data');
$configFolder = [System.IO.Path]::Combine($localAppDataFolder, 'MiKTeX', 'Config');
If ($Error.Count -ne 0)
{
    Write-Error 'Failed to determine the folders for installation.';
    Return;
}

Write-Verbose 'Fixing the installation by MiKTeX Setup Utility (its uninstaller is broken)...' -Verbose;

Write-Verbose '    Copying uninstaller shim script.' -Verbose;
$uninstAsset = [System.IO.Path]::Combine($PSScriptRoot, 'Uninstall-MiKTeX.ps1.dat');
$uninstTarget = [System.IO.Path]::Combine($installFolder, 'Uninstall-MiKTeX.ps1');
Copy-Item -LiteralPath $uninstAsset -Destination $uninstTarget -Force;

Write-Verbose '    Prepare to fix Uninstall registry key.' -Verbose;
$uninstKeyRegex = [regex]::new('^(Software\\Microsoft\\Windows.*?\\Uninstall\\.*?);UninstallString$', 'IgnoreCase');
$uninstLog = [System.IO.Path]::Combine($installFolder, 'miktex\config\uninst.log')
$uninstKey = @(Get-Content $uninstLog -ErrorAction SilentlyContinue | ForEach-Object -Begin { $inhkcu = $False } -Process {
    If ([string]::IsNullOrWhiteSpace($_))
    {
        Continue;
    }
    $_ = $_.Trim();
    If ($_.ToLowerInvariant() -eq '[hkcu]')
    {
        $inhkcu = $True;
    }
    ElseIf ($_.StartsWith('['))
    {
        $inhkcu = $False;
    }
    ElseIf ($inhkcu)
    {
        $testMatch = $uninstKeyRegex.Match($_);
        If ($testMatch.Success)
        {
            'HKCU:\' + $testMatch.Groups[1].Value;
        }
    }
});
$uninstKey = @($uninstKey.ToLowerInvariant() | Sort-Object | Get-Unique);
If ($uninstKey.Count -ne 1)
{
    Write-Error 'Failed to determine Uninstall registry key from uninst.log file.';
    Return;
}
$uninstKey = $uninstKey[0];

Write-Verbose '    Setting DisplayIcon.' -Verbose;
$uninstIcon = [System.IO.Path]::Combine($installFolder, 'miktex\bin\x64\miktex-console.exe');
Set-ItemProperty -LiteralPath $uninstKey -Name 'DisplayIcon' -Value $uninstIcon -Force;
If ($Error.Count -ne 0)
{
    Write-Error 'Failed to set DisplayIcon value.';
    Return;
}

Write-Verbose '    Setting UninstallString to shim uninstaller.' -Verbose;
$uninstStr = 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command . "';
$uninstStr += $uninstTarget;
$uninstStr += '"';
Set-ItemProperty -LiteralPath $uninstKey -Name 'UninstallString' -Value $uninstStr -Force;
If ($Error.Count -ne 0)
{
    Write-Error 'Failed to set UninstallString value.';
    Return;
}

Write-Verbose '    Removing LocalRepository value from registry (as if installed offline).' -Verbose;
Remove-ItemProperty -Path 'HKCU:\Software\MiKTeX.org\MiKTeX\*\MPM' -Name 'LocalRepository' -Force -ErrorAction 'Ignore';

Write-Verbose '    Computing size of installation.' -Verbose;
$estimatedSize = 0;
Get-ChildItem -LiteralPath $installFolder,$dataFolder,$configFolder -File -Recurse |
    ForEach-Object { $estimatedSize += $_.Length / 1KB };
$estimatedSize = [int]$estimatedSize;

Write-Verbose '    Setting EstimatedSize value under Uninstall registry key.' -Verbose;
Set-ItemProperty -LiteralPath $uninstKey -Name 'EstimatedSize' -Value $estimatedSize -Force;
If ($Error.Count -ne 0)
{
    Write-Error 'Failed to set EstimatedSize value.';
    Return;
}
Write-Verbose 'Finished fixing.' -Verbose;
