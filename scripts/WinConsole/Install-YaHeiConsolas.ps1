#Requires -Version 4.0
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Installs YaHei Consolas Hybrid font.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/tree/master/scripts/WinConsole
#>

$script:ErrorActionPreference = 'Stop';

Try
{
    $script:consoleTtf = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont';
    $script:page936 = Get-ItemProperty -Path $consoleTtf | Get-Member -MemberType NoteProperty | Where-Object Name -match '0*936';
    If (($page936 | Where-Object { (Get-ItemPropertyValue -Path $consoleTtf -Name $_.Name) -eq 'YaHei Consolas Hybrid' }).Length -gt 0)
    {
        Exit 0;
    }
    Else
    {
        $script:propName = '936';
        While (@($page936 | Where-Object Name -eq $propName).Count -gt 0)
        {
            $propName = '0' + $propName;
        }
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont' -Name $propName -Value 'YaHei Consolas Hybrid';
        Exit 0;
    }
}
Catch
{
    Exit 1;
}
