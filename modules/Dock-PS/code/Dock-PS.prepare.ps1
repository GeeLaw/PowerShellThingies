If ($PSVersionTable.BuildVersion.Build -lt 14393)
{
    Write-Warning -Message 'Dock-PS will not work until Windows 10 Anniversary Update, Version 1607 (Build 14393).';
    Add-Type -TypeDefinition (Get-Content -Path (Join-Path $PSScriptRoot 'Helper.cs') -Raw) | Out-Null;
}
Else
{
    Add-Type -TypeDefinition (Get-Content -Path (Join-Path $PSScriptRoot 'Helper.14393.cs') -Raw) | Out-Null;
}

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { [DockPSHelper.AppBarHelper]::CleanUp(); } | Out-Null;
