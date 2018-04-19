# oobe.then

![](logo.png)

The script is used after OOBE of a newly-installed Windows copy. After OOBE, Gee Law often does the following:

- Create a surrogate administrator account and do the following:
  1. Disable background (hero image of Windows 10) on Welcome Screen;
  2. Change computer name (default is `DESKTOP-<Unique ID>`);
  3. Set locale to `zh-CN`;
  4. Set `RegisteredOwner` and `RegisteredOrganization` in `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion`;
  5. Remove useless Microsoft Store apps;
  6. Update PowerShell help content;
  7. Create an administrator account linked to his Microsoft account;
  8. In `lusrmgr.msc`, change the newly created account name to a shorter one;
- Sign into Micorosft account and do the following:
  1. Verify with multi-factor authentication so that passwords sync;
  2. Set console style;
  3. Install software;
  4. Import [daily restore point creation job](https://github.com/GeeLaw/daily-restore-point);
  5. Remove the surrogate account and start using Windows.

This script automates most work done in the first stage (step 1 to 6). To set console style, use `WinConsole` script.

Some of you might have seen the old version of `oobe.then.ps1`, which is now outdated. The new version is revamped and contains interactive interface to select which appx packages are to be removed.
