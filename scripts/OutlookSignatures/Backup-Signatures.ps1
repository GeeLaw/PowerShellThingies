#Requires -Version 2.0

<#
.SYNOPSIS
    Creates a backup of signatures stored in Outlook for Desktop (non-Store
    verseion).

.DESCRIPTION
    The script copies %LOCALAPPDATA%\Microsoft\Signatures to the script
    directory.

    The recommended way of using these scripts is to copy them to a dedicated
    folder in OneDrive (or DropBox if you want), which enables automatic
    uploading.

.PARAMETER Name
    The name of the backup. Defaults to "unixts-<timestamp>".

.LINK
    https://github.com/GeeLaw/PowerShellThingies/tree/master/scripts/OutlookSignatures

#>
[CmdletBinding()]
Param
(
    [string]$Name = '?auto'
)

Process
{
    $local:ErrorActionPreference = 'Stop';
    Push-Location $PSScriptRoot;
    Try
    {
        If ($Name -eq '?auto')
        {
            Write-Verbose 'Name not supplied, generating from Unix timestamp.';
            $Name = ([System.UInt64]([datetime]::UtcNow - [datetime]::new(1970, 1, 1)).TotalSeconds).ToString();
            $Name = 'unixts-' + $Name;
        }
        Write-Verbose "The backup name is: $Name";
        If ((Test-Path ".\$Name"))
        {
            Write-Error "A backup of name $Name already exists.";
        }
        $local:source = [System.IO.Path]::Combine(
            [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData),
            'Microsoft',
            'Signatures');
        If (-not (Test-Path $local:source -PathType 'Container'))
        {
            Write-Error "The source ($local:source) does not exist or is not a folder.";
        }
        Copy-Item -LiteralPath $local:source -Destination ".\$Name" -Force -Recurse -PassThru:$false;
        Write-Verbose 'Backup was successful.';
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
