[CmdletBinding()]
Param
(
  [Parameter()]
  [string]$ScratchDirectory = '?',
  [Parameter()]
  [ScriptBlock]$FailFastTemplate = {}
)

$ProgramName = 'Clever PDF Open Handler';
$CLSID = '{82EDE266-3BF0-435D-9F9A-21AE88AAEF6C}';
$ExeSource = [System.IO.Path]::Combine($PSScriptRoot, 'launchpdf.exe');
$ExeFolder = [System.IO.Path]::Combine(
  [System.Environment]::GetFolderPath(
    [System.Environment+SpecialFolder]::LocalApplicationData,
    [System.Environment+SpecialFolderOption]::Create),
  'Programs', 'launchpdf');
$ExeTarget = [System.IO.Path]::Combine($ExeFolder, 'launchpdf.exe');
$ExeName = 'launchpdf.exe';
$ProgID = 'Acrobat.Document.DC';

If (-not (Test-Path $ExeSource))
{
  Write-Error -Category 'NotEnabled' -ErrorId 'LaunchPDF.NotCompiled' -Message '"launchpdf.exe" is not found --- did you forget to compile it?';
  Return;
}

If (Test-Path $ExeFolder)
{
  Write-Verbose -Message 'Removing old executable folder.';
  $processes = @(Get-Process -Name 'launchpdf' -ErrorAction 'Ignore');
  If ($processes.Count -ne 0)
  {
    $processes | Stop-Process | Out-Null;
    $processes | ForEach-Object { $_.WaitForExit(100); } | Out-Null;
  }
  Remove-Item $ExeFolder -Force -Recurse;
}

New-Item $ExeFolder -Force -ItemType Directory | Out-Null;
Copy-Item -LiteralPath $ExeSource -Destination $ExeTarget -Force | Out-Null;
Write-Verbose -Message 'Copied executable file.';

$regPath = "HKCU:\Software\Classes\CLSID\$CLSID";
If (Test-Path $regPath)
{
  Write-Verbose -Message 'Removing old CLSID registration.';
  Remove-Item $regPath -Force -Recurse;
}

New-Item -Path $regPath -Value $ProgramName -Force | Out-Null;
New-Item -Path "$regPath\LocalServer32" `
  -Value "`"$ExeTarget`"" -Force | Out-Null;
Write-Verbose -Message 'Finished CLSID registration.';

$regPath = "HKCU:\Software\Classes\Applications\$ExeName";
If (Test-Path $regPath)
{
  Write-Verbose -Message 'Removing old Applications registration.';
  Remove-Item $regPath -Force -Recurse;
}

New-Item -Path $regPath -Force | Out-Null;
Set-ItemProperty -LiteralPath $regPath `
  -Name 'FriendlyAppName' -Value $ProgramName | Out-Null;
Set-ItemProperty -LiteralPath $regPath -Name 'NoOpenWith' -Value '' | Out-Null;
Set-ItemProperty -LiteralPath $regPath -Name 'IsHostApp' -Value '' | Out-Null;
Set-ItemProperty -LiteralPath $regPath -Name 'NoStartPage' -Value '' | Out-Null;
New-Item -Path "$regPath\shell" -Force -Value 'cleveropen' | Out-Null;
New-Item -Path "$regPath\shell\cleveropen" -Force -Value 'Clever &Open' | Out-Null;
New-Item -Path "$regPath\shell\cleveropen\command" -Force `
  -Value "`"$ExeTarget`" `"%1`"" | Out-Null;
New-Item -Path "$regPath\shell\cleveropen\DropTarget" -Force |
  Set-ItemProperty -Name 'CLSID' -Value $CLSID | Out-Null;
New-Item -Path "$regPath\SupportedTypes" -Force |
  Set-ItemProperty -Name '.pdf' -Value '' | Out-Null;
Write-Verbose -Message 'Finished Applications registration.';

$regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\$ExeName";
If (Test-Path $regPath)
{
  Write-Verbose -Message 'Removing old App Paths registration.';
  Remove-Item $regPath -Force -Recurse;
}
New-Item -Path $regPath -Force -Value $ExeTarget |
  Set-ItemProperty -Name 'DropTarget' -Value $CLSID | Out-Null;
Write-Verbose -Message 'Finished App Paths registration.';

$regPath = "HKCU:\Software\Classes\$ProgID";
If (Test-Path $regPath)
{
  Write-Verbose -Message 'Removing old ProgID registration.';
  Remove-Item $regPath -Force -Recurse;
}

New-Item -Path "$regPath\shell" -Force -Value 'cleveropen' | Out-Null;
New-Item -Path "$regPath\shell\cleveropen" -Force -Value 'Clever &Open' | Out-Null;
New-Item -Path "$regPath\shell\cleveropen\command" -Force `
  -Value "`"$ExeTarget`" `"%1`"" | Out-Null;
New-Item -Path "$regPath\shell\cleveropen\DropTarget" -Force |
  Set-ItemProperty -Name 'CLSID' -Value $CLSID | Out-Null;
Write-Verbose -Message 'Finished ProgID registration.';
