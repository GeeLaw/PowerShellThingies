[CmdletBinding(SupportsShouldProcess = $True)]
Param ()

Begin
{
    $script:Changes = "Disabling show frequented/recent items in Quick Access.`n" +
        "Enabling check boxes for selection.`n" +
        "Do not show full path in the title bar.`n" +
        "Show hidden/system files.`n" +
        "Show empty drives.`n" +
        "Show file extensions.`n" +
        "Show libraries in navigation pane.`n" +
        "Open Explorer to This PC.`n" +
        "Use color for compressed/encrypted files.`n";
    If (-not $PSCmdlet.ShouldProcess("Making the following changes to Explorer:`n" + $Changes,
        "About to making the following changes to Explorer:`n" + $Changes + "`nDo you want to continue?",
        'Change File Explorer Options'))
    {
        Break;
    }
    $script:PathShallow = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer';
    $script:PathDeep = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';
    Write-Verbose 'Writing registry.';
}

Process
{
    If (-not (Test-Path -LiteralPath $PathDeep))
    {
        New-Item -Path $PathDeep -Force | Out-Null;
    }
    @(
        @{ 'Name' = 'ShowFrequent'; 'Value' = 0 },
        @{ 'Name' = 'ShowRecent'; 'Value' = 0 }
    ) | ForEach-Object {
        $_['LiteralPath'] = $PathShallow;
        $_['Type'] = 'DWord';
        $_['Force'] = $True;
        Set-ItemProperty @_;
    };
    @(
        @{ 'Name' = 'AutoCheckSelect'; 'Value' = 1 },
        @{ 'Name' = 'DontPrettyPath'; 'Value' = 0 },
        @{ 'Name' = 'Hidden'; 'Value' = 1 },
        @{ 'Name' = 'HideDrivesWithNoMedia'; 'Value' = 0 },
        @{ 'Name' = 'HideFileExt'; 'Value' = 0 },
        @{ 'Name' = 'HideIcons'; 'Value' = 0 },
        @{ 'Name' = 'LaunchTo'; 'Value' = 1 },
        @{ 'Name' = 'ShowCompColor'; 'Value' = 1 },
        @{ 'Name' = 'ShowEncryptCompressedColor'; 'Value' = 1 },
        @{ 'Name' = 'ShowSuperHidden'; 'Value' = 1 }
    ) | ForEach-Object {
        $_['LiteralPath'] = $PathDeep;
        $_['Type'] = 'DWord';
        $_['Force'] = $True;
        Set-ItemProperty @_;
    };
}

End
{
    Write-Verbose 'Finished updating the settings.';
}
