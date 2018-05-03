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
    6. Sets DWM inactive window colour.
    7. Updates help content for PowerShell.

    All steps can be turned off in advance with switches;
    in addition, step 2, 3, 4 and 5 can be cancelled on demand.

.PARAMETER DisableLogonBackground
    Disables background image on Welcome Screen without confirmation.

.PARAMETER ComputerName
    Sets a new computer name. If blank, computer name is left unchanged. If not supplied, the value is asked interactively.

.PARAMETER Locale
    Sets a new locale. If blank, locale is left unchanged. If not supplied, the value is asked interactively.

.PARAMETER RegisteredOwner
    Sets a new registered owner. If blank, the value is left unchanged. If not supplied, the value is asked interactively. You must not supply the value as "!". To set the registered owner to "!", supply "?!".

.PARAMETER RegisteredOrganization
    Sets a new registered organisation. If blank, the value is left unchanged. If not supplied, the value is asked interactively. You must not supply the value as "!". To set the registered organisation to "!", supply "?!".

.PARAMETER SkipRemovePackages
    Skips the step to interactively select which appx (provisioned) packages to remove.

.PARAMETER SetDwmInactiveColor
    Forces the user to choose a DWM inactive window title bar colour.

.PARAMETER UpdateHelp
    Updates help for PowerShell without confirmation.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/tree/master/scripts/oobe.then
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
Param
(
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogonBackground,
    [Parameter(Mandatory = $false)]
    [string]$ComputerName = '!',
    [Parameter(Mandatory = $false)]
    [string]$Locale = '!',
    [Parameter(Mandatory = $false)]
    [string]$RegisteredOwner = '!',
    [Parameter(Mandatory = $false)]
    [string]$RegisteredOrganization = '!',
    [Parameter(Mandatory = $false)]
    [switch]$SkipRemovePackages,
    [Parameter(Mandatory = $false)]
    [switch]$SetDwmInactiveColor,
    [Parameter(Mandatory = $false)]
    [switch]$UpdateHelp
)
Process
{
    <# Disables logon background on Welcome Screen. #>
    If ($DisableLogonBackground -or $PSCmdlet.ShouldProcess('Welcome Screen', 'Disable background image'))
    {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'DisableLogonBackgroundImage' -Type DWord -Value 1;
        Write-Verbose 'Disabled logon background image of Welcome Screen.';
    }
    Else
    {
        Write-Verbose 'Did not disable logon background image of Welcome Screen.';
    }
    <# Renames computer. #>
    If ($ComputerName -eq '!')
    {
        $ComputerName = Read-Host -Prompt "Current computer name is `"$((Get-WmiObject Win32_ComputerSystem).Name)`".`nType a new name (blank to ignore)";
        $ComputerName = $ComputerName.Trim();
    }
    If (-not [string]::IsNullOrWhiteSpace($ComputerName))
    {
        $local:renameReturnValue = (Get-WmiObject Win32_ComputerSystem).Rename($ComputerName).ReturnValue;
        $local:renameMessage = ((net.exe helpmsg $renameReturnValue) -join "`n").Trim();
        $local:renameErrorMessage = "Renaming computer returned $renameReturnValue [$renameMessage].";
        Write-Verbose $renameErrorMessage;
        If ($renameReturnValue -ne 0)
        {
            Write-Error -ErrorId "Win32Error_$renameReturnValue" -Message $renameErrorMessage;
        }
    }
    Else
    {
        Write-Verbose 'Did not rename computer.';
    }
    <# Sets a new locale. #>
    If ($Locale -eq '!')
    {
        $local:currentLocale = Get-WinSystemLocale;
        $Locale = Read-Host -Prompt "Current locale is $($currentLocale.Name) ($($currentLocale.LCID)) $($currentLocale.DisplayName).`nType a new locale (e.g., zh-CN; blank to ignore)";
    }
    If (-not [string]::IsNullOrWhiteSpace($Locale))
    {
        Set-WinSystemLocale -SystemLocale $Locale;
        Write-Verbose "Tried setting locale to $Locale.";
    }
    Else
    {
        Write-Verbose 'Did not set a new locale.';
    }
    <# Set a new registered owner. #>
    If ($RegisteredOwner -eq '!')
    {
        $local:currentRegisteredOwner = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').RegisteredOwner;
        If ($currentRegisteredOwner -eq $null)
        {
            $currentRegisteredOwner = '(not set)';
        }
        Else
        {
            $currentRegisteredOwner = "`"$currentRegisteredOwner`"";
        }
        $RegisteredOwner = Read-Host -Prompt "Current registered owner is $currentRegisteredOwner.`nTo ignore, type blank.`nNon-empty response will set RegisteredOwner.`nThe first question mark will be removed, so that `"?`" sets RegisteredOwner to `"`".`nEnter your choice";
    }
    If (-not [string]::IsNullOrEmpty($RegisteredOwner))
    {
        If ($RegisteredOwner.StartsWith('?'))
        {
            $RegisteredOwner = $RegisteredOwner.Substring(1);
        }
        Set-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
            -Name 'RegisteredOwner' -Value $RegisteredOwner;
        Write-Verbose "Set RegisteredOwner to `"$RegisteredOwner`".";
    }
    Else
    {
        Write-Verbose 'Did not set RegisteredOwner.';
    }
    <# Set a new registered organisation. #>
    If ($RegisteredOrganization -eq '!')
    {
        $local:currentRegisteredOrganization = (Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').RegisteredOrganization;
        If ($currentRegisteredOrganization -eq $null)
        {
            $currentRegisteredOrganization = '(not set)';
        }
        Else
        {
            $currentRegisteredOrganization = "`"$currentRegisteredOrganization`"";
        }
        $RegisteredOrganization = Read-Host -Prompt "Current registered organisation is $currentRegisteredOrganization.`nTo ignore, type blank.`nNon-empty response will set RegisteredOrganization.`nThe first question mark will be removed, so that `"?`" sets RegisteredOrganization to `"`".`nEnter your choice";
    }
    If (-not [string]::IsNullOrEmpty($RegisteredOrganization))
    {
        If ($RegisteredOrganization.StartsWith('?'))
        {
            $RegisteredOrganization = $RegisteredOrganization.Substring(1);
        }
        Set-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
            -Name 'RegisteredOrganization' -Value $RegisteredOrganization;
        Write-Verbose "Set RegisteredOrganization to `"$RegisteredOrganization`".";
    }
    Else
    {
        Write-Verbose 'Did not set RegisteredOrganization.';
    }
    If (-not $SkipRemovePackages)
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
                $lastInput = Read-Host -Prompt "Type `"?`" to open helper again, `"??`" to choose empty list.`nPaste the summary";
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
    Else
    {
        Write-Verbose 'Skipped the step to remove appx (provisioned) packages.';
    }
    If ($SetDwmInactiveColor -or $PSCmdlet.ShouldProcess('Inactive window title bar color', 'Set as 0xff66666666'))
    {
        Set-ItemProperty -LiteralPath 'HKCU:\SOFTWARE\Microsoft\Windows\DWM' -Name 'AccentColorInactive' -Value 0xff666666 -Type DWord;
        Write-Verbose 'Set inactive window title bar color to 0xff666666.';
    }
    Else
    {
        Write-Verbose 'Did not set inactive window title bar color.';
    }
    If ($UpdateHelp -or $PSCmdlet.ShouldProcess('PowerShell help content', 'Update'))
    {
        Update-Help -Force;
        Write-Verbose 'Updated help content for PowerShell.';
    }
    Else
    {
        Write-Verbose 'Did not update help content for PowerShell.';
    }
    Write-Verbose 'Done. You might want to restart your computer.';
}
