# Switch-User

When invoked from a usual session, the cmdlet tries to run `PowerShell.exe` as administrator and preserve the current working directory. If the invocation is successful, the calling window is hidden. When the elevated prompt exits, the calling window restores its state, providing a seamless experience of elevation.

You can also supply `Credential` parameter to run PowerShell as another user. This parameter accepts value from the pipeline.

When invoked from an elevated prompt, the cmdlet asks for a credential to start PowerShell as unless you have specified `Crendetial` parameter.

**IMPORTANT** This cmdlet should only be invoked from Windows PowerShell.
