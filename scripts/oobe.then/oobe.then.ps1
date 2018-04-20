#Requires -Version 5.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Prepares a newly-installed Windows copy for Gee Law's daily use.

.DESCRIPTION
    The script does the following:
    1. Disables background on Welcome Screen;
    2. Prompts the user to rename the computer;
    3. Prompts the user to set a new locale;
    4. Prompts the user to change the registration information;
    5. Interactively removes user-selected Microsoft Store apps from the system;
    6. Updates help content for PowerShell.

    All steps can be turned off in advance with switches;
    in addition, step 2, 3, 4 and 5 can be cancelled on demand.

.PARAMETER NoDisableLogonBackground
    Skips the step to disable background on Welcome Screen.
    Note that setting this switch does not revert the policy
    to enable background.

.PARAMETER NoRenameComputer
    Skips the step to rename computer.

.PARAMETER NoSetLocale
    Skips the step to set a new locale.

.PARAMETER NoRegistration
    Skips the step to change the registration information.

.PARAMETER NoRemovePackages
    Skips the step to interactively select which appx packages to remove.

.PARAMETER NoUpdateHelp
    Skips the step to update help.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/tree/master/scripts/oobe.then
#>
[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $false)]
    [switch]$NoDisableLogonBackground,
    [Parameter(Mandatory = $false)]
    [switch]$NoRenameComputer,
    [Parameter(Mandatory = $false)]
    [switch]$NoSetLocale,
    [Parameter(Mandatory = $false)]
    [switch]$NoRegistration,
    [Parameter(Mandatory = $false)]
    [switch]$NoRemovePackages,
    [Parameter(Mandatory = $false)]
    [switch]$NoUpdateHelp
)
Process
{
    $local:ErrorActionPreference = 'Inquire';
    $local:WarningPreference = 'Continue';
    $local:VerbosePreference = 'Continue';

    If (-not $NoDisableLogonBackground)
    {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableLogonBackgroundImage' -Type DWord -Value 1;
        Write-Verbose 'Disabled logon background image of Welcome Screen.';
    }
    If (-not $NoRenameComputer)
    {
        $local:computerSystem = Get-WmiObject Win32_ComputerSystem;
        $local:newName = Read-Host -Prompt "Current computer name is `"$($computerSystem.Name)`", type a new name or ignore";
        If ($newName.Trim() -ne '')
        {
            $local:retRename = $computerSystem.Rename($newName).ReturnValue;
            $local:renameMsg = ((net.exe helpmsg $retRename) -join "`n").Trim();
            $local:renameErr = "Renaming computer returned $retName [$renameMsg].";
            Write-Verbose $renameErr;
            If ($local:retRename -ne 0)
            {
                Write-Error -ErrorId "Win32Error_$retRename" -Message $renameErr;
            }
        }
        Else
        {
            Write-Verbose 'Did not rename computer.';
        }
    }
    If (-not $NoSetLocale)
    {
        $currentLocale = Get-WinSystemLocale;
        $newLocale = Read-Host -Prompt "Current locale is $($currentLocale.Name) ($($currentLocale.LCID)) $($currentLocale.DisplayName),`nEnter a new locale name (e.g., zh-CN; empty to leave untouched)";
        If ($newLocale -ne '')
        {
            Set-WinSystemLocale -SystemLocale $newLocale;
            Write-Verbose "Tried setting locale to $newLocale.";
        }
        Else
        {
            Write-Verbose "Did not change locale.";
        }
    }
    If (-not $NoRegistration)
    {
        $regReg = Get-Item -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT';
        $regReg = $regReg.OpenSubKey('CurrentVersion', $true);
        Try
        {
            $regUserName = $regReg.GetValue('RegisteredOwner');
            If ($regUserName -eq $null)
            {
                $regUserName = 'not set';
            }
            Else
            {
                $regUserName = '"' + $regUserName + '"';
            }
            $regOrg = $regReg.GetValue('RegisteredOrganization');
            If ($regOrg -eq $null)
            {
                $regOrg = 'not set';
            }
            Else
            {
                $regOrg = '"' + $regOrg + '"';
            }
            Write-Verbose "Current registered owner is $regUserName.";
            Write-Verbose 'To leave the setting untouched, enter nothing.';
            Write-Verbose 'Non-empty input will set RegisteredOwner.';
            Write-Verbose 'The first question mark will be removed, so that "?" sets it to "".';
            $regUserName = Read-Host 'Enter your choice';
            If ($regUserName -ne '')
            {
                If ($regUserName.StartsWith('?'))
                {
                    $regUserName = $regUserName.Substring(1);
                }
                $regReg.SetValue('RegisteredOwner', $regUserName, 'String');
                Write-Verbose "Set RegisteredOwner to `"$regUserName`".";
            }
            Else
            {
                Write-Verbose 'Did not set RegisteredOwner.';
            }
            Write-Verbose "Current registered organisation is $regOrg.";
            Write-Verbose 'Same syntax as that for RegisteredOwner.';
            $regOrg = Read-Host 'Enter your choice';
            If ($regOrg -ne '')
            {
                If ($regOrg.StartsWith('?'))
                {
                    $regOrg = $regOrg.Substring(1);
                }
                $regReg.SetValue('RegisteredOrganization', $regOrg, 'String');
                $regReg.Flush();
                Write-Verbose "Set RegisteredOrganization to `"$regOrg`".";
            }
            Else
            {
                Write-Verbose 'Did not set RegisteredOrganization.';
            }
        }
        Catch
        {
            Throw;
        }
        Finally
        {
            $regReg.Close();
        }
    }
    If (-not $NoRemovePackages)
    {
        $getChoice = { Param([string]$HelperFile, [UInt32]$Length, [string]$Hash)
            $lastInput = '?';
            $choice = @();
            While ($true)
            {
                $choice = @();
                If ($lastInput -eq '?')
                {
                    Start-Process -FilePath $HelperFile;
                }
                $lastInput = Read-Host -Prompt 'Paste the summary, type "?" to open helper again, or type "??" to choose empty list';
                If ($lastInput -eq '?')
                {
                    Continue;
                }
                If ($lastInput -eq '??' -or $lastInput -eq $Hash)
                {
                    Break;
                }
                If ($lastInput.StartsWith($Hash + ','))
                {
                    $choice = $lastInput.Substring($Hash.Length + 1).Split(',');
                    $lastInput = $choice.Count;
                    $choice = $choice | ForEach-Object { $i = 0; If ([UInt32]::TryParse($_, [ref]$i) -and $i -lt $Length) { $i } };
                    If ($choice.Count -eq $lastInput)
                    {
                        Break;
                    }
                }
                Write-Warning 'Invalid input.';
                $lastInput = '';
            }
            $choice | Write-Output;
        };
        $appxPackages = Get-AppxPackage -AllUsers |
            Where-Object { $_.SignatureKind -eq [Windows.ApplicationModel.PackageSignatureKind]::Store } |
            Where-Object { -not $_.IsFramework };
        $hash = [System.Guid]::NewGuid().ToString('n');
        $packageType = 'AppxPackage';
        $packageData = $appxPackages | Select-Object Name, Publisher, PackageFamilyName | ConvertTo-Json;
        $templateFile = [System.IO.Path]::Combine($PSScriptRoot, 'template.html');
        $templateFile = Get-Content -LiteralPath $templateFile -Encoding UTF8 -Raw;
        $templateFile =$templateFile.Replace('/*9a841860c8724172918b13b6418d1fae*/', "'$hash', '$packageType', $packageData");
        $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $hash + '.html');
        [System.IO.File]::WriteAllText($tempFile, $templateFile);
        & $getChoice -HelperFile $tempFile -Length $appxPackages.Length -Hash $hash |
            ForEach-Object { Remove-AppxPackage -Package ($appxPackages[$_].PackageFullName) -AllUsers; };
        $provisionedPackages = Get-AppxProvisionedPackage -Online;
        $hash = [System.Guid]::NewGuid().ToString('n');
        $packageType = 'AppxProvisionedPackage';
        $packageData = $provisionedPackages | Select-Object DisplayName, PublisherId, PackageName | ConvertTo-Json;
        $templateFile = [System.IO.Path]::Combine($PSScriptRoot, 'template.html');
        $templateFile = Get-Content -LiteralPath $templateFile -Encoding UTF8 -Raw;
        $templateFile =$templateFile.Replace('/*9a841860c8724172918b13b6418d1fae*/', "'$hash', '$packageType', $packageData");
        $tempFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $hash + '.html');
        [System.IO.File]::WriteAllText($tempFile, $templateFile);
        & $getChoice -HelperFile $tempFile -Length $provisionedPackages.Length -Hash $hash |
            ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName ($provisionedPackages[$_].PackageName); };
    }
    If (-not $NoUpdateHelp)
    {
        Update-Help -Force;
        Write-Verbose 'Updated help content for PowerShell.';
    }
    Write-Verbose 'Done. You might want to restart your computer.';
}
