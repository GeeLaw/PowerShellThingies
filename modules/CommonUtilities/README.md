# CommonUtilities

![](logo.png)

## Get

To install this module for all users, use the following script:

```PowerShell
#Requires -RunAsAdministrator
Install-Module -Name CommonUtilities -Scope AllUsers;
```

To install this module for the current user, use the following script:

```PowerShell
Install-Module -Name CommonUtilities -Scope CurrentUser;
```

## Functions

| Name | Alias(es) | Synopsis |
| --- | --- | --- |
| [New-Password](New-Password.md) | newpwd | Generates a cryptographically-safe password. |
| [Sign-Scripts](Sign-Scripts.md) | sign | Signs your PowerShell scripts with your certificate. |
| [Switch-User](Switch-User.md) | su | A better ‘Run PowerShell as Administrator’ and ‘Run PowerShell as another user’. |
| Restart-Host | restart | Restarts PowerShell. |
| [Get/Set/Remove-FastCredential](FastCredential.md) | (N/A) | Commands related to managing saved credentials. |
