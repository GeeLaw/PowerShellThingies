#Requires -Version 4.0

<#
.SYNOPSIS
    Sets the console style to Gee Law's preference.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/tree/master/scripts/WinConsole
#>
[CmdletBinding()]
Param()

If ($Host.Version -lt '4.0')
{
    Write-Error 'This script requires PowerShell 4.0 or higher.';
    Return;
}
Else
{
    Write-Verbose "Install Microsoft YaHei Mono if you haven't." -Verbose;
    Write-Verbose "https://github.com/Microsoft/WSL/issues/2463#issuecomment-334692823" -Verbose;

    Write-Warning 'The script is going to reset all your console default preference to default.';

    Remove-Item -Path 'HKCU:\Console\*' -Force -Recurse;

    @{
        'ColorTable00' = 0x00000000; # Black
        'ColorTable01' = 0x00b20000; # DarkBlue
        'ColorTable02' = 0x0000a600; # DarkGreen
        'ColorTable03' = 0x00646400; # DarkCyan
        'ColorTable04' = 0x00000099; # DarkRed
        'ColorTable05' = 0x00b200b2; # DarkMagenta
        'ColorTable06' = 0x0000ade5; # DarkYellow
        'ColorTable07' = 0x00cccccc; # Gray
        'ColorTable08' = 0x00666666; # DarkGray
        'ColorTable09' = 0x00ff0000; # Blue
        'ColorTable10' = 0x0000d900; # Green
        'ColorTable11' = 0x00e5e500; # Cyan
        'ColorTable12' = 0x000000e5; # Red
        'ColorTable13' = 0x00e500e5; # Magenta
        'ColorTable14' = 0x0000ffff; # Yellow
        'ColorTable15' = 0x00ffffff; # White
        'CtrlKeyShortcutsDisabled' = 0x00000000;
        'CursorSize' = 0x00000019;
        'EnableColorSelection' = 0x00000000;
        'ExtendedEditKey' = 0x00000001;
        'ExtendedEditKeyCustom' = 0x00000000;
        'FilterOnPaste' = 0x00000000;
        'FontFamily' = 0x00000036;
        'FontSize' = 0x00180000;
        'FontWeight' = 0x00000190;
        'ForceV2' = 0x00000001;
        'FullScreen' = 0x00000000;
        'HistoryBufferSize' = 0x00000032;
        'HistoryNoDup' = 0x00000000;
        'InsertMode' = 0x00000001;
        'LineSelection' = 0x00000001;
        'LineWrap' = 0x00000001;
        'LoadConIme' = 0x00000001;
        'NumberOfHistoryBuffers' = 0x00000004;
        'PopupColors' = 0x0000003e; # Yellow on DarkCyan
        'QuickEdit' = 0x00000001;
        'ScreenBufferSize' = 0x03e80050;
        'ScreenColors' = 0x0000000f; # White on Black
        'ScrollScale' = 0x00000001;
        'TrimLeadingZeros' = 0x00000000;
        'WindowAlpha' = 0x000000ff;
        'WindowSize' = 0x001e0050;
        'WordDelimiters' = 0x00000000;
        'CurrentPage' = 0x00000002;
        'CodePage' = 0x000003a8
    }.GetEnumerator() | ForEach-Object `
    {
        Set-ItemProperty -Path 'HKCU:\Console' -Name $_.Name -Type 'DWord' -Value $_.Value;
    }

    Set-ItemProperty -Path 'HKCU:\Console' -Name 'FaceName' -Type 'String' -Value 'Microsoft YaHei Mono';

    Write-Verbose 'Finished configuring your console.' -Verbose;
    Write-Verbose 'You should recreate shortcuts of console applications you have used so that they get the default look.' -Verbose;
}
