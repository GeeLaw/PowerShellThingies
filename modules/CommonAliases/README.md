# CommonAliases

## Get

To install this module for all users, use the following script:

```PowerShell
#Requires -RunAsAdministrator
Install-Module -Name CommonAliases -Scope AllUsers;
```

To install this module for the current user, use the following script:

```PowerShell
Install-Module -Name CommonAliases -Scope CurrentUser;
```

## Aliases

This module exports several common alises to make PowerShell easier to use.

| Alias | Value |
| --- | --- |
| `new` | `New-Object` |
| `clip` | `Set-Clipboard` |
| `paste` | `Get-Clipboard` |
| `poke` | `Invoke-WebRequest` |
| `2json` | `ConvertTo-Json` |
| `json2` | `ConvertFrom-Json` |
| `2csv` | `ConvertTo-Csv` |
| `csv2` | `ConvertFrom-Csv` |
| `2html` | `ConvertTo-Html` |
| `ping` | `Test-Connection` |
| `find` | `Select-String` |
| `grep` | `Select-String` |
| `tasklist` | `Get-Process` |
| `taskkill` | `Stop-Process` |

## Function

Invoke `Use-CommonAliases` to import the module. Since you invoke a function inside the module, the whole module is imported. Usually invoking an alias also does the same thing, e.g., invoking `new` imports the module. But if you try to invoke `ping`, PowerShell chooses `ping.exe` instead of the alias that is not yet imported. However, once imported, PowerShell favours `ping => Test-Connection` and you have to use `ping.exe` to explicitly use the command-line executable.
