[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $True)]
    [string]$ScratchDirectory,
    [Parameter(Mandatory = $True)]
    [ScriptBlock]$FailFastTemplate
)

$Error.Clear();
$FailFast = { & $FailFastTemplate 'https://miktex.org/download' ($args[0]) 'Please install MiKTeX yourself.'; };

$localZip = [System.IO.Path]::Combine($ScratchDirectory, 'mtsetup.zip');
$localExe = [System.IO.Path]::Combine($ScratchDirectory, 'miktexsetup.exe');
Remove-Item -LiteralPath $localZip -Force -Recurse -ErrorAction Ignore;
Remove-Item -LiteralPath $localExe -Force -Recurse -ErrorAction Ignore;

Start-BitsTransfer -Source 'https://miktex.org/download/win/miktexsetup-x64.zip' -Destination $localZip -Description 'Download MiKTeX Setup Utility.';
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to download MiKTeX Setup Utility.';
    Return;
}

Expand-Archive -LiteralPath $localZip -DestinationPath $ScratchDirectory -Force;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to decompress MiKTeX Setup Utility.';
    Return;
}

$localRepo = [System.IO.Path]::Combine($ScratchDirectory, 'miktex-repo');
Remove-Item -LiteralPath $localRepo -Force -Recurse -ErrorAction Ignore;

Write-Verbose 'Downloading basic packages...' -Verbose;
$setupArgs = '--local-package-repository="';
$setupArgs += $localRepo;
$setupArgs += '" --package-set=basic download';
$setupProc = Start-Process -FilePath $localExe -ArgumentList $setupArgs -PassThru -WindowStyle Minimized;
$setupProc.WaitForExit();
If ($setupProc.ExitCode -ne 0)
{
    & $FailFast 'Failed to download basic packages to local repository.';
    Return;
}
Write-Verbose 'Finished downloading.' -Verbose;

$localAppDataFolder = [System.Environment]::GetFolderPath('LocalApplicationData', 'Create');
$installFolder = [System.IO.Path]::Combine($localAppDataFolder, 'Programs', 'MiKTeX');
$dataFolder = [System.IO.Path]::Combine($localAppDataFolder, 'MiKTeX', 'Data');
$configFolder = [System.IO.Path]::Combine($localAppDataFolder, 'MiKTeX', 'Config');
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to determine the folders for installation.';
    Return;
}

Write-Verbose 'Installing from local repository...' -Verbose;
$setupArgs = '--local-package-repository="';
$setupArgs += $localRepo;
$setupArgs += '" --use-registry --modify-path'
$setupArgs += ' --package-set=basic';
$setupArgs += ' --program-folder=MiKTeX --shared=no';
$setupArgs += " --user-install=`"$installFolder`"";
$setupArgs += " --user-data=`"$dataFolder`"";
$setupArgs += " --user-config=`"$configFolder`"";
$setupArgs += ' install';
$setupProc = Start-Process -FilePath $localExe -ArgumentList $setupArgs -PassThru -WindowStyle Minimized;
$setupProc.WaitForExit();
If ($setupProc.ExitCode -ne 0)
{
    & $FailFast 'Failed to install MiKTeX from local repository.';
    Return;
}
Write-Verbose 'Finished MiKTeX Setup Utility installer.' -Verbose;

Write-Verbose 'Fixing the installation by MiKTeX Setup Utility (its uninstaller is broken)...' -Verbose;
$FailFast = { & $FailFastTemplate $localRepo ($args[0]) 'Please fix the installation yourself.'; }

$newPath = [System.Environment]::GetEnvironmentVariable('PATH', 'User') + ';' + [System.Environment]::GetEnvironmentVariable('PATH', 'Machine')
[System.Environment]::SetEnvironmentVariable('PATH', $newPath, 'Process')

Write-Verbose '    Setting default paper to A4 and enabling auto-install of missing packages on-the-fly.' -Verbose;
initexmf --enable-installer --default-paper-size=a4 --set-config-value=[MPM]AutoInstall=1 | Out-Host;

Write-Verbose '    Copying uninstaller shim script.' -Verbose;
$uninstAsset = [System.IO.Path]::Combine($PSScriptRoot, 'Uninstall-MiKTeX.ps1.dat');
$uninstTarget = [System.IO.Path]::Combine($installFolder, 'Uninstall-MiKTeX.ps1');
Copy-Item -LiteralPath $uninstAsset -Destination $uninstTarget -Force;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to copy the uninstall script to the target folder.';
    Return;
}

Write-Verbose '    Prepare to fix Uninstall registry key.' -Verbose;
$uninstKeyRegex = [regex]::new('^(Software\\Microsoft\\Windows.*?\\Uninstall\\.*?);', 'IgnoreCase');
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
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to read uninst.log file.';
    Return;
}
If ($uninstKey.Count -ne 1)
{
    & $FailFast 'Failed to determine Uninstall registry key from uninst.log file.';
    Return;
}
$uninstKey = $uninstKey[0];

Write-Verbose '    Setting DisplayIcon.' -Verbose;
$uninstIcon = [System.IO.Path]::Combine($installFolder, 'miktex\bin\x64\miktex-console.exe');
Set-ItemProperty -LiteralPath $uninstKey -Name 'DisplayIcon' -Value $uninstIcon -Force;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to set DisplayIcon value.';
    Return;
}

Write-Verbose '    Setting UninstallString to shim uninstaller.' -Verbose;
$uninstStr = 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command . "';
$uninstStr += $uninstTarget;
$uninstStr += '"';
Set-ItemProperty -LiteralPath $uninstKey -Name 'UninstallString' -Value $uninstStr -Force;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to set UninstallString value.';
    Return;
}

Write-Verbose '    Removing LocalRepository value from registry (as if installed offline).' -Verbose;
If ('localrepository' -in @((Get-Item -Path 'HKCU:\Software\MiKTeX.org\MiKTeX\*\MPM').GetValueNames()).ToLowerInvariant())
{
    Remove-ItemProperty -Path 'HKCU:\Software\MiKTeX.org\MiKTeX\*\MPM' -Name 'LocalRepository' -Force;
}
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to remove LocalRepository value.';
    Return;
}

Write-Verbose '    Installing cm-super package (better typesetting result).' -Verbose;
mpm --install=cm-super | Out-Host;

Write-Verbose '    Computing size of installation.' -Verbose;
$estimatedSize = 0;
Get-ChildItem -LiteralPath $installFolder,$dataFolder,$configFolder -File -Recurse |
    ForEach-Object { $estimatedSize += $_.Length / 1KB };
$estimatedSize = [int]$estimatedSize;

Write-Verbose '    Setting EstimatedSize value under Uninstall registry key.' -Verbose;
Set-ItemProperty -LiteralPath $uninstKey -Name 'EstimatedSize' -Value $estimatedSize -Force;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to set EstimatedSize value.';
    Return;
}
Write-Verbose 'Finished fixing.' -Verbose;
