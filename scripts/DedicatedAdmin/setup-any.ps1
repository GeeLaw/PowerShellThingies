$script:ErrorActionPreference = 'Inquire';

Set-ExecutionPolicy -ExecutionPolicy 'Unrestricted' -Scope 'CurrentUser' -Force;
Set-ExecutionPolicy -ExecutionPolicy 'Unrestricted' -Scope 'Process' -Force;

<# Prevent Explorer from running. Custom shell. #>
& {

$explorer = [System.IO.Path]::Combine(
    [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Windows),
    'explorer.exe');
$acl = Get-Acl -LiteralPath $explorer;

$whoami = ((& ([System.IO.Path]::Combine(
    [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::System),
    'whoami.exe'))) -join '').Trim().Split('\\');
$me = [System.Security.Principal.NTAccount]::new($whoami[0], $whoami[1]);
$acl.SetOwner($me);
Set-Acl -LiteralPath $explorer -AclObject $acl;

$denyMeExecute = [System.Security.AccessControl.FileSystemAccessRule]::new(
    $me,
    [System.Security.AccessControl.FileSystemRights]::ExecuteFile,
    [System.Security.AccessControl.AccessControlType]::Deny
);
$acl.AddAccessRule($denyMeExecute);
Set-Acl -LiteralPath $explorer -AclObject $acl;

$trustedInstaller = [System.Security.Principal.NTAccount]::new('NT SERVICE', 'TrustedInstaller');
$acl.SetOwner($trustedInstaller);
Set-Acl -LiteralPath $explorer -AclObject $acl;

$shellPolicyKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System';
If (-not (Test-Path -LiteralPath $shellPolicyKey))
{
    New-Item -Path $shellPolicyKey -Force;
}
Set-ItemProperty -LiteralPath $shellPolicyKey `
    -Name 'Shell' -Value ((Get-Process -Id $PID).MainModule.FileName) -Type 'String';

$winConsole = [System.IO.Path]::Combine($PSScriptRoot, '..', 'WinConsole', 'WinConsole.ps1');
& $winConsole;

} | Out-Null;

<# History clearer, small utility, profile. #>
& {

$vba = [System.IO.Path]::Combine($PSScriptRoot, '..', 'Install-Apps', 'PerUser', 'Remove-PSReadlineHistory.vbs.dat');
$vbaTarget = [System.IO.Path]::Combine(
    [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile),
    'Clear-PSReadlineHistory.vbs');
Copy-Item -LiteralPath $vba -Destination $vbaTarget -Force;

$envedit = [System.IO.Path]::Combine($PSScriptRoot, '..', 'SurrogateUser', 'Open-EnvironmentVariableEditor.ps1');
$enveditTarget = [System.IO.Path]::Combine(
    [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile),
    'Open-EnvironmentVariableEditor.ps1');
Copy-Item -LiteralPath $envedit -Destination $enveditTarget -Force;

If (-not (Test-Path ([System.IO.Path]::GetDirectoryName($PROFILE))))
{
    New-Item -Path ([System.IO.Path]::GetDirectoryName($PROFILE)) -ItemType Directory -Force;
}
$pfile = [System.IO.Path]::Combine($PSScriptRoot, 'profile.ps1');
Copy-Item -LiteralPath $pfile -Destination $PROFILE -Force;

} | Out-Null;

<# File extensions without UWP, folder options. #>
& {

$installPhotoViewer = [System.IO.Path]::Combine($PSScriptRoot, '..', 'SurrogateUser', 'Install-WindowsPhotoViewer.ps1');
& $installPhotoViewer;

$installWmp = [System.IO.Path]::Combine($PSScriptRoot, '..', 'SurrogateUser', 'Use-MediaPreviewHandler.ps1');
& $installWmp;

$setExplorerOptions = [System.IO.Path]::Combine($PSScriptRoot, '..', 'SurrogateUser', 'Set-ExplorerOptions.ps1');
& $setExplorerOptions;

} | Out-Null;

<# Modules. #>
& {

$moduleFolder = [System.IO.Path]::Combine($PSScriptRoot, '..', '..', 'modules');
Get-ChildItem -LiteralPath $moduleFolder -Filter '*.psd1' -File -Recurse -Force |
    ForEach-Object {
        $moduleManifest = Test-ModuleManifest -Path ($_.FullName);
        $moduleTarget = [System.IO.Path]::Combine(
            [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments),
            'WindowsPowerShell',
            'Modules',
            $moduleManifest.Name,
            $moduleManifest.Version.ToString()
        );
        $moduleSource = [System.IO.Path]::Combine($_.FullName, '..', '*');
        If (-not (Test-Path -LiteralPath $moduleTarget))
        {
            New-Item -Path $moduleTarget -ItemType Directory -ErrorAction 'Ignore';
            Copy-Item $moduleSource -Destination $moduleTarget -Recurse;
        }
    };

} | Out-Null;

<# Theming #>
& {

$dwmKey = 'HKCU:\SOFTWARE\Microsoft\Windows\DWM';
Set-ItemProperty -LiteralPath $dwmKey -Name 'AccentColorInactive' -Value 0xff666666 -Type DWord;
Set-ItemProperty -LiteralPath $dwmKey -Name 'ColorPrevalence' -Value 0x1 -Type DWord;

$themeKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';
Set-ItemProperty -LiteralPath $themeKey -Name 'AppsUseLightTheme' -Value 0x0 -Type DWord;
Set-ItemProperty -LiteralPath $themeKey -Name 'ColorPrevalence' -Value 0x1 -Type DWord;
Set-ItemProperty -LiteralPath $themeKey -Name 'EnableTransparency' -Value 0x0 -Type DWord;

} | Out-Null;
