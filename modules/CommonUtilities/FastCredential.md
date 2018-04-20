# Get/Set/Remove-FastCredential

A fast credential is simply a credential encrypted for the current user saved somewhere. A typical scenario is when you want to isolate some software from your account. Let’s take Chrome for an example. In an elevated PowerShell, do the following:

```PowerShell
$passwd = New-Password -UseSecureString;
New-LocalUser -Name 'Chrome' -FullName 'Chrome User' `
    -Description 'A user dedicated to running Chrome.' ·
    -Password $passwd `
    -AccountNeverExpires `
    -PasswordNeverExpires `
    -UserMayNotChangePassword;
[pscredential]::new('Chrome', $passwd) | Set-FastCredential;
Get-FastCredential -UserName 'Chrome' | Switch-User;
```

Then, in the prompt for Chrome User, do the following:

```PowerShell
Start-Process iexplore
```

Then download Chrome from Google to `C:\Users\Chrome\Downloads`, and do the following:

```PowerShell
Set-Location C:\Users\Chrome\Downloads
Invoke-Item <chrome-installer>.exe
```

Install Chrome for Chrome User only. The following command can be used to launch Chrome:

```PowerShell
Start-Process powershell -Credential (Get-FastCredential Chrome) -WorkingDirectory 'C:\' -ArgumentList '-NonInteractive', '-Command', "Start-Process 'C:\Users\Chrome\AppData\Local\Google\Chrome\Application\chrome.exe' -WorkingDirectory 'C:\Users\Chrome\AppData\Local\Google\Chrome\Application'" -WindowStyle Hidden
```

Exit the prompt for Chrome User and go back to your normal account. Copy the above command to the clipboard, and do the following:

```PowerShell
$command = Get-Clipboard;
$encodedCommand = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command));
```

Now, `$encodedCommand` will be:

```text
UwB0AGEAcgB0AC0AUAByAG8AYwBlAHMAcwAgAHAAbwB3AGUAcgBzAGgAZQBsAGwAIAAtAEMAcgBlAGQAZQBuAHQAaQBhAGwAIAAoAEcAZQB0AC0ARgBhAHMAdABDAHIAZQBkAGUAbgB0AGkAYQBsACAAQwBoAHIAbwBtAGUAKQAgAC0AVwBvAHIAawBpAG4AZwBEAGkAcgBlAGMAdABvAHIAeQAgACcAQwA6AFwAJwAgAC0AQQByAGcAdQBtAGUAbgB0AEwAaQBzAHQAIAAnAC0ATgBvAG4ASQBuAHQAZQByAGEAYwB0AGkAdgBlACcALAAgACcALQBDAG8AbQBtAGEAbgBkACcALAAgACIAUwB0AGEAcgB0AC0AUAByAG8AYwBlAHMAcwAgACcAQwA6AFwAVQBzAGUAcgBzAFwAQwBoAHIAbwBtAGUAXABBAHAAcABEAGEAdABhAFwATABvAGMAYQBsAFwARwBvAG8AZwBsAGUAXABDAGgAcgBvAG0AZQBcAEEAcABwAGwAaQBjAGEAdABpAG8AbgBcAGMAaAByAG8AbQBlAC4AZQB4AGUAJwAgAC0AVwBvAHIAawBpAG4AZwBEAGkAcgBlAGMAdABvAHIAeQAgACcAQwA6AFwAVQBzAGUAcgBzAFwAQwBoAHIAbwBtAGUAXABBAHAAcABEAGEAdABhAFwATABvAGMAYQBsAFwARwBvAG8AZwBsAGUAXABDAGgAcgBvAG0AZQBcAEEAcABwAGwAaQBjAGEAdABpAG8AbgAnACIAIAAtAFcAaQBuAGQAbwB3AFMAdAB5AGwAZQAgAEgAaQBkAGQAZQBuAA==
```

Now, do the following:

```PowerShell
[System.Environment]::SetEnvironmentVariable('OpenChrome', $encodedCommand, 'User')
```

Create a shortcut to the following command:

```text
powershell.exe -NonInteractive -WindowStyle Hidden -EncodedCommand %OpenChrome%
```

And now you can use the shortcut to open Chrome as Chrome User.
