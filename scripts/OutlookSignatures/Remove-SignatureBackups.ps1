#Requires -Version 2.0

<#
.SYNOPSIS
    Removes specified backups of signatures.

.DESCRIPTION
    The script only removes things that are located under the script
    directory.

    The recommended way of using these scripts is to copy them to a dedicated
    folder in OneDrive (or DropBox if you want), which enables automatic
    deletion.

.PARAMETER Name
    The names of the backups to be removed.
    If not supplied, only backups whose name is "unixts-<timestamp>" are
    subject to removal, and the latest backup is NOT removed.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/tree/master/scripts/OutlookSignatures

.EXAMPLE
    .\Remove-Signature.ps1 -WhatIf -Verbose

    Displays which "unixts-<timestamps>" backup is the latest and which are to
    be removed.

#>
[CmdletBinding(SupportsShouldProcess = $true)]
Param
(
    [string[]]$Name = @('?old')
)

Process
{
    $local:ErrorActionPreference = 'Stop';
    Push-Location $PSScriptRoot;
    Try
    {
        If ($Name.Count -eq 1 -and $Name[0] -eq '?old')
        {
            Write-Verbose 'Names are not supplied. Defaulting to removing all old backups.';
            $local:regex = [regex]::new('^unixts-([0-9]+)$');
            $local:backups = Get-ChildItem 'unixts-*' -Directory | Where-Object Name -match $local:regex;
            $local:latest = $local:backups | ForEach-Object {
                [System.UInt64]::Parse($local:regex.Match($_.Name).Groups[1].Value)
            } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum;
            Write-Verbose "Resolved latest backup: unixts-$latest";
            $local:backups = $local:backups | Where-Object {
                [System.UInt64]::Parse($local:regex.Match($_.Name).Groups[1].Value) -ne $local:latest };
            $Name = $local:backups | Select-Object -ExpandProperty Name;
        }
        If ($Name.Count -eq 0)
        {
            Write-Verbose 'Nothing to remove.';
            Return;
        }
        ForEach ($item in $Name)
        {
            If ($PSCmdlet.ShouldProcess($item, "Remove backup"))
            {
                Write-Verbose "Removing backup: $item";
                Remove-Item -LiteralPath ".\$item" -Force -Recurse -Confirm:$false -WhatIf:$false;
            }
        }
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
