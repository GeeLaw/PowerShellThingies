#Requires -Version 2.0

<#
.SYNOPSIS
    Restores the specified backup of signatures to the system.

.DESCRIPTION
    Restores the specified backup of signatures to the system by copying the
    specified backup to %LOCALAPPDATA%\Microsoft\Signatures.

    The recommended way of using these scripts is to copy them to a dedicated
    folder in OneDrive (or DropBox if you want), which enables automatic
    synchronisation.

.PARAMETER Name
    The name of the backup to be restored.
    If not supplied, the latest backup whose name is "unixts-<timestamp>" is
    used.

.PARAMETER WhatIf
    Displays what would have been done. Note that this is a normal switch,
    not backed by SupportsShouldProcess, and that there is no -Confirm switch
    for this script.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/tree/master/scripts/OutlookSignatures

.EXAMPLE
    .\Restore-Signature.ps1 -Name my-signatures

    Restores the backup named "my-signatures" to the system.

.EXAMPLE
    .\Restore-Signature.ps1

    Restores the latest backup in the form "unixts-<timestamp>" to the system.

#>
[CmdletBinding()]
Param
(
    [string]$Name = '?auto',
    [switch]$WhatIf
)

Process
{
    $local:ErrorActionPreference = 'Stop';
    Push-Location $PSScriptRoot;
    Try
    {
        If ($Name -eq '?auto')
        {
            Write-Verbose 'Name not supplied, finding latest backup from Unix timestamp.';
            $local:regex = [regex]::new('^unixts-([0-9]+)$');
            $Name = Get-ChildItem 'unixts-*' -Directory | Where-Object Name -match $local:regex | ForEach-Object {
                [System.UInt64]::Parse($local:regex.Match($_.Name).Groups[1].Value)
            } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum;
            If ($Name -eq $null)
            {
                Write-Error 'No backup found for automatic restoring.';
            }
            $Name = "unixts-$Name";
        }
        Write-Verbose "The backup name is: $Name";
        If (-not (Test-Path ".\$Name" -PathType 'Container'))
        {
            Write-Error "A backup of name $Name does not exist.";
        }
        $local:target = [System.IO.Path]::Combine(
            [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData),
            'Microsoft',
            'Signatures');
        If ($WhatIf)
        {
            Write-Host "What if: Moving `"$local:target`" to temporary folder.";
            Write-Host "What if: Copying the backup `"$Name`" to `"$local:target`".";
            Return;
        }
        Try
        {
            $local:moved = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [guid]::NewGuid().ToString('n'));
            Write-Verbose "Current signatures will be moved to: $local:moved";
            Move-Item -LiteralPath $local:target -Destination $local:moved -Force;
            Write-Verbose 'Successfully moved current signatures.';
        }
        Catch
        {
            Write-Verbose 'Could not move current signatures. Perhaps they do not exist.';
        }
        If ((Test-Path $local:target))
        {
            Write-Error "The target ($local:target) cannot be moved.";
        }
        Copy-Item -LiteralPath ".\$Name" -Destination $local:target -Force -Recurse -PassThru:$false;
        Write-Verbose 'Restoration was successful.';
    }
    Catch
    {
        Throw;
    }
    Finally
    {
        Pop-Location;
    }
}
