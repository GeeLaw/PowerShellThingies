# DedicatedAdmin

I use these scripts to configure the built-in administrator. I have decided to use a Limited User Account for my everyday activities, and use Fast User Switching to switch to the administrator for maintenance tasks.

Usage:

1. In the LUA, `runas` the administrator and run `setup-any.ps1`.
2. Log on as the administrator from the Welcome Screen, and run `setup-interactive.ps1`.

The first step makes sure the built-in administrator never runs Explorer, so that no appx packages are ever registered. The built-in administrator will use PowerShell as the shell program.

**Note**: If you would like to reconfigure an account from scratch so that File Explorer is never run, you must delete the user profile using `sysdm.cpl`. If the profile to delete belongs to the only enabled administrator, first reboot the machine and log on to the LUA so that the administrator's profile isn't in use, then run `runas /noprofile /u:<AdminUserName> "control sysdm.cpl"` to open `sysdm.cpl` with administrative privilege without loading the user profile, and finally delete the user profile.

## Tasks performed by `setup-any.ps1`

0. Sets the execution policy to `Unrestricted` for the administrator. So be careful!
1. Denys the current user (the administrator) from executing `%WINDIR%\explorer.exe`.
2. Sets PowerShell as the shell program of this user (using the `Shell` value of `HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System`).
3. Runs `WinConsole.ps1` to configure the appearance of consoles.
4. Installs `Clear-PSReadlineHistory.vbs` into the user profile, which will be used to clear PowerShell history.
5. Installs `Open-EnvironmentVariableEditor.ps1` into the user profile, which will provide a utility to open Environment Variable Editor without using File Explorer. However, this is not necessary, as the administrator could just run `sysdm.cpl`.
6. Installs the PowerShell profile, which further configures the appearance, provides a custom prompt and provides `Clear-History` that clears the session and persistent PowerShell history.
7. Runs `Install-WindowsPhotoViewer.ps1` so that the administrator can see photos without Photos app.
8. Runs `Use-MediaPreviewHandler.ps1` so that the administrator can use Windows Media Player to preview videos.
9. Runs `Set-ExplorerOptions.ps1` so that the administrator sees hidden files etc.
10. Installs all the modules in this repository to the user.
11. Sets some theming options.

## Tasks performed by `setup-interactive.ps1`

1. Installs Sysinternals to the Documents folder. If you want it to be on `PATH`, do it yourself with `Open-EnvironmentVariableEditor`.
2. Installs Visual Studio Code (per-user, latest stable). It also assumes that you have Git installed and sets the default Git editor to Visual Studio Code.
3. Sets the current theme to Windows 10 default theme (`aero.theme`).
