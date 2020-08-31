[CmdletBinding()]
Param()

$CLSID = '{82EDE266-3BF0-435D-9F9A-21AE88AAEF6C}';
$ExeFolder = [System.IO.Path]::Combine(
  [System.Environment]::GetFolderPath(
    [System.Environment+SpecialFolder]::LocalApplicationData,
    [System.Environment+SpecialFolderOption]::Create),
  'Programs', 'launchpdf');
$ProgID = 'Acrobat.Document.DC';

$regPath = "HKCU:\Software\Classes\$ProgID";
If (Test-Path $regPath)
{
  Remove-Item $regPath -Force -Recurse;
  Write-Verbose -Message 'Removed ProgID registration.';
}
Else
{
  Write-Verbose -Message 'ProgID registration not found.';
}

$regPath = "HKCU:\Software\Classes\Applications\$ExeName";
If (Test-Path $regPath)
{
  Write-Verbose -Message 'Removing Applications registration.';
  Remove-Item $regPath -Force -Recurse;
}
Else
{
  Write-Verbose -Message 'Applications registration not found.';
}

$regPath = "HKCU:\Software\Classes\CLSID\$CLSID";
If (Test-Path $regPath)
{
  Write-Verbose -Message 'Removing CLSID registration.';
  Remove-Item $regPath -Force -Recurse;
}
Else
{
  Write-Verbose -Message 'CLSID registration not found.';
}

If (Test-Path $ExeFolder)
{
  Write-Verbose -Message 'Removing executable folder.';
  $processes = @(Get-Process -Name 'launchpdf' -ErrorAction 'Ignore');
  If ($processes.Count -ne 0)
  {
    $processes | Stop-Process | Out-Null;
    $processes | ForEach-Object { $_.WaitForExit(100); } | Out-Null;
  }
  Remove-Item $ExeFolder -Force -Recurse;
}
Else
{
  Write-Verbose -Message 'Executable folder not found.';
}
