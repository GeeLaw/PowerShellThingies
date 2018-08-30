# Install-Apps

This script automates installation of several apps.

## How to use

Use this script with `oobe.then` and `WinConsole`. Before creating your daily account, perform `Install-AppsPerMachine.ps1`. In your daily account, perform `Install-AppsPerUser.ps1`.

Usually you do not have to invoke individual script for each app. However, it is nevertheless possible. Run `Install-CertainApp.ps1` with `ScratchDirectory` set to some temporary folder, and `FailFastTemplate` set to the following script block:

```PowerShell
{
Start-Process ($args[0]);
$args | Select-Object -Skip 1 |
    Write-Host -BackgroundColor Black -ForegroundColor Red;
Pause;
$Error.Clear();
}
```
