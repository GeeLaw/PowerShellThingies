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

# Method 1: Detect 7-Zip and use it to deploy iTunes.

$detect7zSuccess = $False;
$programFiles = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFiles);
$programFiles32 = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFilesX86);
If (-not $detect7zSuccess)
{
    $detected7z = [System.IO.Path]::Combine($programFiles, '7-Zip', '7z.exe');
    If ((Test-Path -LiteralPath $detected7z -PathType Leaf))
    {
        $detect7zSuccess = $True;
    }
}

If (-not $detect7zSuccess)
{
    $detected7z = [System.IO.Path]::Combine($programFilesX86, '7-Zip', '7z.exe');
    If ((Test-Path -LiteralPath $detected7z -PathType Leaf))
    {
        $detect7zSuccess = $True;
    }
}

If (-not $detect7zSuccess)
{
    $detected7z = @([System.IO.Path]::Combine($programFiles, '*'), [System.IO.Path]::Combine($programFilesX86, '*'));
    $detected7z = Get-ChildItem $detected7z -Include '7z.exe' -File -Force -Recurse -ErrorAction Ignore |
        Select-Object -ExpandProperty FullName -First 1;
    If ($detected7z -ne $null)
    {
        $detect7zSuccess = $True;
    }
}

If (-not $detect7zSuccess)
{
    Write-Verbose 'Did not detect 7-Zip. Falling back to the installer.' -Verbose;
}

If ($detect7zSuccess)
{
    Write-Verbose "Detected 7-Zip at $detected7z" -Verbose;
    Write-Verbose 'Extracting files from the installer...' -Verbose;
    $expandTarget = [System.IO.Path]::Combine($ScratchDirectory, 'itunes');
    $expandArgs = "x -bd `"-o$expandTarget`" -y -- `"$localPath`"";
    $expandProc = Start-Process -FilePath $detected7z -ArgumentList $expandArgs -PassThru -WindowStyle Minimized;
    $expandProc.WaitForExit();
    If ($expandProc.ExitCode -ne 0)
    {
        $Error.Clear();
        $detect7zSuccess = $False;
        Write-Verbose '7-Zip extraction failed. Falling back to the installer.' -Verbose;
    }
    Write-Verbose 'Files are extracted.' -Verbose;
}

If ($detect7zSuccess)
{
    $expected = @('AppleApplicationSupport.msi', 'AppleApplicationSupport64.msi', 'AppleMobileDeviceSupport6464.msi', 'AppleSoftwareUpdate.msi', 'Bonjour64.msi', 'iTunes64.msi', 'SetupAdmin.exe');
    $expected = $expected | ForEach-Object { [System.IO.Path]::Combine($expandTarget, $_) };
    $actualCount = @(Get-ChildItem $expandTarget -Force -File -Recurse).Count;
    If ($actualCount -ne $expected.Count)
    {
        $Error.Clear();
        $detect7zSuccess = $False;
        Write-Verbose 'Unrecognised iTunes installer structure. Falling back to the installer.' -Verbose;
    }
    Else
    {
        $nonExistent = @($expected | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) }).Count;
        If ($nonExistent -ne 0)
        {
            $Error.Clear();
            $detect7zSuccess = $False;
            Write-Verbose 'Unrecognised iTunes installer structure. Falling back to the installer.' -Verbose;
        }
    }
}

If ($detect7zSuccess)
{
    ForEach ($msiPkg In $expected)
    {
        If ($msiPkg.EndsWith('.msi'))
        {
            $msiExec = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$msiPkg`" /passive /norestart" -PassThru;
            $msiExec.WaitForExit();
            If ($msiExec.ExitCode -ne 0)
            {
                $Error.Clear();
                $detect7zSuccess = $False;
                Write-Verbose "Failed to install MSI Package: $msiPkg" -Verbose;
                Write-Verbose "Falling back to the installer." -Verbose;
                Break;
            }
        }
    }
}

# Method 2: Install iTunes with user intervention.
If (-not $detect7zSuccess)
{
    Write-Verbose 'Installing iTunes using its installer: user intervetion required!' -Verbose;
    $itunesInst = Start-Process -FilePath $localPath -PassThru;
    $itunesInst.WaitForExit();
    If ($itunesInst.ExitCode -ne 0)
    {
        & $FailFast 'iTunes installer failed.';
        Return;
    }
}
