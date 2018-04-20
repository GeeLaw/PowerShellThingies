<#
.Synopsis
    Generates a cryptographically secure password.

.Description
    The cmdlet generates strong passwords with cryptographically secure random number generator.

    By default this cmdlets generates a password of length 16 with upper case, lower case, numeral and special characters.

    "newpwd" is the alias of this cmdlet.

.Parameter Length
    The length of the output. It must be at least 4 and at most 256. The default is 16.

.Parameter RNGImplementation
    The name of the implementation of cryptographically secure random number generation algorithm.

    "RNGAlgorithm" and "RNG" are the aliases of this parameter.

.Parameter NoUpperCaseCharacters
    Suppresses upper case characters from the output. These include ABCDEFGHIJKLMNOPQRSTUVWXYZ.

    "NoUC" is the alias of this switch.

.Parameter NoLowerCaseCharacters
    Suppresses lower case characters from the output. These include abcdefghijklmnopqrstuvwxyz.

    "NoLC" is the alias of this switch.

.Parameter NoNumeralCharacters
    Suppresses numeral characters from the output. These include 0123456789.

    "NoNum" is the alias of this switch.

.Parameter NoSpecialCharacters
    Suppresses special characters from the output. These include `~!@#$%^&*()_+-={}[]|\;':"<>?,./ and space.

    "NoSpecial" is the alias of this switch.

.Parameter AllowSimilarCharacters
    Allowes similar characters in the output. These include 1, l and I, 0 and O and `, ' and ".

.Parameter AllowSpace
    Allowes the space character in the output.

.Parameter UseSecureString
    Pipes out a System.Security.SecureString instead of string.

.Parameter Elder
    Forces the output to end with "+1s". If this switch is set, -UseSecureString will be cleared even if set explicitly. However, NONE of -NoLowerCaseCharacters, -NoNumeralCharacters and -NoSpecialCharacters are required to be cleared.

    "ls" is the alias of this switch. Therefore you get one second subtracted if you extend the elder's life for one second.

.Example
    New-Password -Length 20 -AllowSimilarCharacters

    This creates a 20-character long password possibly with similar characters.

    Possible output: "X9kw5Bc2~W^16EzuU]jJ"

.Example
    New-Password -NoSpecialCharacters -UseSecureString

    This creates a 16-character long password without special characters as a SecureString.

    Possible output: A System.Security.SecureString object.

.Example
    New-Password -Elder

    This creates a 16-character long password that ends with "+1s".

    Possible output: ">nvaM!$HAAr;v+1s"

.Link
    https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/CommonUtilities/New-Password.md

#>
Function New-Password
{
    [CmdletBinding()]
    [Alias('newpwd')]
    Param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateRange(4, 256)]
        [int]$Length = 16,
        [Alias("RNGAlgorithm", "RNG")]
        [string]$RNGImplementation,
        [Alias("NoUC")]
        [switch]$NoUpperCaseCharacters,
        [Alias("NoLC")]
        [switch]$NoLowerCaseCharacters,
        [Alias("NoNum")]
        [switch]$NoNumeralCharacters,
        [Alias("NoSpecial")]
        [switch]$NoSpecialCharacters,
        [switch]$AllowSimilarCharacters,
        [switch]$AllowSpace,
        [switch]$UseSecureString,
        [Alias("ls", "o-o")]
        [switch]$Elder
    )
    Process
    {
        $local:uc = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
        $local:lc = 'abcdefghijkmnopqrstuvwxyz';
        $local:nu = '234567892345678923456789';
        $local:sp = '~!@#$%^&*()_+{}|[]\-=:;<>?,./';
        If ($AllowSimilarCharacters)
        {
            $uc += 'IO'; $lc += 'l';
            $nu += '010101'; $sp += "'" + '`"';
        }
        If ($AllowSpace)
        {
            $sp += ' ';
        }
        $local:lib = '';
        If (-not $NoUpperCaseCharacters)
        {
            $lib += $uc;
        }
        If (-not $NoLowerCaseCharacters)
        {
            $lib += $lc;
        }
        If (-not $NoNumeralCharacters)
        {
            $lib += $nu;
        }
        If (-not $NoSpecialCharacters)
        {
            $lib += $sp;
        }
        If ($lib.Length -eq 0)
        {
            Write-Error 'At least one category of characters must be allowed.';
            Return;
        }
        If ($Elder)
        {
            If ($UseSecureString)
            {
                Write-Warning '-UseSecureString is cleared by -Elder.';
            }
            $UseSecureString = $false;
            <# Sets these switches so that the algorithm no longer checks them.
             # But $lib already contains the specified characters, therefore
             # the generation rule is still correct.
             #>
            $NoLowerCaseCharacters = $true;
            $NoNumeralCharacters = $true;
            $NoSpecialCharacters = $true;
            $Length -= 3;
        }
        $local:rnd = $null;
        If ([string]::IsNullOrEmpty($RNGImplementation))
        {
            $rnd = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider';
        }
        Else
        {
            $rnd = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider' -ArgumentList $RNGImplementation;
        }
        $local:result = $null;
        $local:byteHolder = New-Object -TypeName 'byte[]' -ArgumentList @(1);
        If ($UseSecureString)
        {
            <# This instance will be disposed immediately in the first round of the loop. #>
            $result = New-Object -TypeName 'System.Security.SecureString';
        }
        $local:hasUC = $false; $local:hasLC = $false; $local:hasNU = $false; $local:hasSP = $false;
        $local:trimming = $false;
        $local:i = 0;
        Do
        {
            $hasUC = $false; $hasLC = $false; $hasNU = $false; $hasSP = $false;
            $trimming = $false;
            If ($UseSecureString)
            {
                $result.Dispose();
                $result = New-Object -TypeName 'System.Security.SecureString';
                For ($i = 0; $i -lt $Length; ++$i)
                {
                    Do
                    {
                        $rnd.GetBytes($byteHolder);
                    }
                    Until ([int]($byteHolder[0] / $lib.Length) -ne [int](256 / $lib.Length));
                    $result.AppendChar($lib[$byteHolder[0] % $lib.Length]);
                    If ($uc.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasUC = $true;
                    }
                    If ($lc.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasLC = $true;
                    }
                    If ($nu.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasNU = $true;
                    }
                    If ($sp.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasSP = $true;
                    }
                    if ($lib[$byteHolder[0] % $lib.Length] -eq ' '[0] -and ($i -eq 0 -or $i -eq ($Length - 1)))
                    {
                        $trimming = $true;
                    }
                }
                $result.MakeReadOnly();
            }
            Else
            {
                $result = '';
                For ($i = 0; $i -lt $Length; ++$i)
                {
                    Do
                    {
                        $rnd.GetBytes($byteHolder);
                    }
                    Until ([int]($byteHolder[0] / $lib.Length) -ne [int](256 / $lib.Length));
                    $result += $lib[$byteHolder[0] % $lib.Length];
                    If ($uc.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasUC = $true;
                    }
                    If ($lc.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasLC = $true;
                    }
                    If ($nu.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasNU = $true;
                    }
                    If ($sp.Contains($lib[$byteHolder[0] % $lib.Length]))
                    {
                        $hasSP = $true;
                    }
                }
                If ($Elder)
                {
                    $result += '+1s';
                }
                If ($result[0] -eq ' '[0] -or $result[$result.Length - 1] -eq ' '[0])
                {
                    $trimming = $true;
                }
            }
            $byteHolder[0] = 0;
        }
        Until (-not $trimming -and ($NoUpperCaseCharacters -or $hasUC) -and ($NoLowerCaseCharacters -or $hasLC) -and ($NoNumeralCharacters -or $hasNU) -and ($NoSpecialCharacters -or $hasSP));
        $rnd.Dispose();
        Return $result;
    }
}


<#
.Synopsis
    Switches to elevated PowerShell or PowerShell run as another user.

.Description
    When called from an usual PowerShell prompt, it tries to start the elevated PowerShell. If it succeeds, the calling window is hidden. When the elevated PowerShell exits (by invoking exit or any other means), the calling window reappears, providing a seamless experience of elevation.

    The same rule applies for switching to another user.

.Link
    https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/CommonUtilities/Switch-User.md

#>
Function Switch-User
{
    [CmdletBinding()]
    [Alias('su')]
    Param
    (
        [Parameter(ValueFromPipeline = $true)]
        [Alias('user', 'as', 'to')]
        [System.Management.Automation.PSCredential]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )
    Process
    {
        $local:ErrorActionPreference = 'Stop';
        If ($Host.Name -ne 'ConsoleHost')
        {
            Write-Error 'This cmdlet can only be invoked from PowerShell.';
            Return;
        }
        $local:IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator');
        $local:currentPathUnicodeBase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes((Get-Location).Path));
        $local:suProcessInitCmd = '& { ';
        $suProcessInitCmd += 'Set-Location -Path ([System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(';
        $suProcessInitCmd += "'";
        $suProcessInitCmd += $currentPathUnicodeBase64;
        $suProcessInitCmd += "'";
        $suProcessInitCmd += '))); ';
        $suProcessInitCmd += '}';
        $local:suProcess = $null;
        $local:currentProcess = $null;
        $local:wasVisible = $true;
        If ($IsAdmin -and [object]::ReferenceEquals($Credential, [System.Management.Automation.PSCredential]::Empty))
        {
            $Credential = Get-Credential -Message 'Please specify the credential to run PowerShell.';
            If ($Credential -eq $null)
            {
                Write-Error 'Action cancelled by user.' -Category OperationStopped;
                Return;
            }
        }
        If ([object]::ReferenceEquals($Credential, $null) -or [object]::ReferenceEquals($Credential, [System.Management.Automation.PSCredential]::Empty))
        {
            $suProcess = Start-Process -PassThru -FilePath 'PowerShell.exe' -Verb 'runas' `
                -ArgumentList @('-NoExit', '-ExecutionPolicy', (Get-ExecutionPolicy).ToString(), '-Command', $suProcessInitCmd);
            If ($suProcess -eq $null)
            {
                Return;
            }
            Write-Verbose "Another process started on $($suProcess.StartTime), ProcessId = $($suProcess.Id).";
            $currentProcess = Get-Process -Id $pid;
            $wasVisible = [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::ShowWindow($currentProcess.MainWindowHandle, 0);
            $suProcess.WaitForExit();
            Write-Verbose "The process exited on $($suProcess.ExitTime).";
            If ($suProcess.ExitCode -eq 0)
            {
                Write-Verbose 'The process exited with code 0.';
            }
            Else
            {
                Write-Warning "The process exited with code $($suProcess.ExitCode).";
            }
        }
        Else
        {
            $suProcess = Start-Process -PassThru -FilePath 'PowerShell.exe' `
                -ArgumentList @('-NoExit', '-ExecutionPolicy', (Get-ExecutionPolicy).ToString(), '-Command', $suProcessInitCmd) `
                -Credential $Credential;
            If ($suProcess -eq $null)
            {
                Return;
            }
            Write-Verbose "Another process started on $($suProcess.StartTime), ProcessId = $($suProcess.Id).";
            $currentProcess = Get-Process -Id $pid;
            $wasVisible = [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::ShowWindow($currentProcess.MainWindowHandle, 0);
            $suProcess.WaitForExit();
            Write-Verbose 'Another process has exited. However, running as another user does not give ExitTime or ExitCode.';
        }
        $suProcess.Dispose();
        If ($wasVisible)
        {
            [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::ShowWindow($currentProcess.MainWindowHandle, 5) | Out-Null;
            [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::SwitchToThisWindow($currentProcess.MainWindowHandle, $True);
            [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::BringWindowToTop($currentProcess.MainWindowHandle) | Out-Null;
            If (-not [__3b043047842e4cfa94dbcb39a5ccf3e5.SwitchUser]::SetForegroundWindow($currentProcess.MainWindowHandle))
            {
                $currentProcess.Dispose();
                Write-Error 'Failed to recover the hidden window.';
                Return;
            }
        }
        $currentProcess.Dispose();
        Return;
    }
}

<#
.Synopsis
    A shortcut for Set-AuthenticodeSignature.

.Description
    Use this cmdlet to sign your code (PowerShell scripts, modules, manifests
    and so on). When no certificate is supplied, the cmdlet tries to use your
    code-signing certificate(s).

    "sign" is the alias of this cmdlet.

.Parameter Scripts
    The path of the scripts to sign. This parameter is mandatory. It receives
    value from the pipeline by value and by property (aliased FullName so that
    you can pipe FileInfo object generated by Get-ChildItem).

.Parameter Certificate
    The certificate to use.

    If unspecified, the cmdlet enumerates all your personal code-signing
    certificates. If there is only one such certificate, the scripts are signed
    with this certificate; otherwise you interactively choose one certificate.
    If no such certificate is found, the cmdlet fails.

.Example
    Sign-Scripts -Scripts $profile

    This line signs your profile script with your personal code-signing
    certificate(s).

.Example
    Get-ChildItem -File -Recurse | Sign-Scripts

    This line signs all the files (including those in subfolders) with your
    personal code-signing certificate(s). This line works best if you have one
    and only one such certificate in your personal store.

.Link
    https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/CommonUtilities/Sign-Scripts.md

#>
Function Sign-Scripts
{
    [CmdletBinding()]
    [Alias('sign')]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [string[]]$Scripts,
        [Parameter(Mandatory = $false)]
        [Alias('with')]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )
    Begin
    {
        If ($Certificate -eq $null)
        {
            $local:certs = Get-ChildItem -LiteralPath 'Cert:\CurrentUser\My' -CodeSigningCert;
            If ($certs.Count -eq 1)
            {
                Write-Verbose 'Signing code with the following certificate:';
                $certs[0] | Format-List | Out-String | Write-Verbose;
                $Certificate = $certs[0];
            }
            ElseIf ($certs.Count -gt 1)
            {
                Write-Host 'Multiple certificates are available in your personal storage.';
                Write-Host;
                $local:i = 0;
                $certs | ForEach-Object {
                        Write-Host "Certificate[$i]:";
                        $_ | Format-List | Out-String | Write-Host;
                        $i = $i + 1;
                    };
                $local:choice = Read-Host -Prompt 'Please specify the certificate';
                $local:choiceInt = 0;
                If ([int]::TryParse($choice, [ref] $choiceInt))
                {
                    If ($choiceInt -ge 0 -and $choiceInt -lt $certs.Count)
                    {
                        $Certificate = $certs;
                    }
                    Else
                    {
                        Throw [IndexOutOfRangeException];
                    }
                }
                Else
                {
                    Throw [FormatException] 'You must specifiy an index.';
                }
            }
            Else
            {
                throw [Exception] 'You do not have a certifcate in your personal storage. Please specify the certificate in the command.';
            }
        }
        If ($Certificate -eq $null)
        {
            Break;
        }
    }
    Process
    {
        If ($Certificate -ne $null)
        {
            Set-AuthenticodeSignature -FilePath $Scripts -Certificate $Certificate;
        }
    }
}

<#
.SYNOPSIS
    Restarts the host.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/tree/master/modules/CommonUtilities

#>
Function Restart-Host
{
    [CmdletBinding()]
    [Alias('restart')]
    Param()
    Process
    {
        Start-Process -FilePath (Get-Process -Id $pid).Path;
        Exit;
    }
}

<#
.SYNOPSIS
    Sets a fast credential.

.DESCRIPTION
    This advanced function stores a credential with default
    encryption method under %LOCALAPPDATA%\FastCredentials.

    It supports user names in the form of USERNAME or
    DOMAIN\USERNAME, where DOMAIN and USERNAME must consist
    of only valid file name characters, and not end with a
    full stop.

    Under proper security configuration (up-to-date Windows,
    BitLocker, proper permission on %USERPROFILE% and strong
    password), the stored credential is only accessible from
    the current user. See the online help for canonical usage.

.PARAMETER Credential
    One single credential to be stored. The value can be piped
    from another command like Get-Credential.

.EXAMPLE
    Get-Credential | Set-FastCredential

    This example reads a credential from GUI and saves it.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/CommonUtilities/FastCredential.md
#>
Function Set-FastCredential
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCredential]$Credential
    )
    Process
    {
        Try
        {
            $local:ssString = ConvertFrom-SecureString -SecureString $Credential.Password;
            $local:localAppData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData);
            If (-not (Test-Path -LiteralPath ([System.IO.Path]::Combine($local:localAppData, 'FastCredentials'))))
            {
                New-Item -Path $local:localAppData -Name 'FastCredentials' -ItemType 'Directory' | Out-Null;
            }
            Push-Location -LiteralPath ([System.IO.Path]::Combine($local:localAppData, 'FastCredentials'));
            Try
            {
                $Credential.UserName.Split('\') | Select-Object -SkipLast 1 | ForEach-Object {
                    If (-not (Test-Path -LiteralPath $_))
                    {
                        New-Item -Name $_ -ItemType 'Directory' | Out-Null;
                    }
                    Set-Location -LiteralPath $_;
                };
            }
            Catch
            {
                Throw;
            }
            Finally
            {
                Pop-Location;
            }
            $local:fileName = [System.IO.Path]::Combine($local:localAppData, 'FastCredentials', $Credential.UserName + '.fastcred');
            [System.IO.File]::WriteAllText($fileName, $ssString);
        }
        Catch
        {
            Throw;
        }
    }
}

<#
.SYNOPSIS
    Retrieves a fast credential.

.DESCRIPTION
    This advanced function reads a credential with default
    encryption method under %LOCALAPPDATA%\FastCredentials.

    It supports user names in the form of USERNAME or
    DOMAIN\USERNAME, where DOMAIN and USERNAME must consist
    of only valid file name characters, and not end with a
    full stop.

.PARAMETER UserName
    User name of the credential to be retrieved.

.EXAMPLE
    Start-Process -FilePath 'powershell' `
        -Credential (Get-FastCredential 'AnotherUser')

    Starts PowerShell as AnotherUser.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/CommonUtilities/FastCredential.md
#>
Function Get-FastCredential
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$UserName
    )
    Process
    {
        Try
        {
            $local:localAppData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData);
            $local:fileName = [System.IO.Path]::Combine($local:localAppData, 'FastCredentials', $UserName + '.fastcred');
            $local:ssString = [System.IO.File]::ReadAllText($fileName);
            $local:ssString = ConvertTo-SecureString -String $local:ssString;
            $local:cred = [PSCredential]::new($UserName, $local:ssString);
            Return $local:cred;
        }
        Catch
        {
            Throw;
        }
    }
}

<#
.SYNOPSIS
    Removes a fast credential.

.DESCRIPTION
    This advanced function removes a credential under
    %LOCALAPPDATA%\FastCredentials.

    It supports user names in the form of USERNAME or
    DOMAIN\USERNAME, where DOMAIN and USERNAME must consist
    of only valid file name characters, and not end with a
    full stop.

.PARAMETER UserName
    User name of the credential to be removed.

.LINK
    https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/CommonUtilities/FastCredential.md
#>
Function Remove-FastCredential
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$UserName
    )
    Process
    {
        Try
        {
            $local:localAppData = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData);
            $local:fileName = [System.IO.Path]::Combine($local:localAppData, 'FastCredentials', $UserName + '.fastcred');
            Remove-Item -LiteralPath $local:fileName -Recurse:$false;
        }
        Catch
        {
            Throw;
        }
    }
}

Export-ModuleMember -Function @('New-Password', 'Switch-User', 'Sign-Scripts', 'Restart-Host', 'Set-FastCredential', 'Get-FastCredential', 'Remove-FastCredential') -Alias @('newpwd', 'su', 'sign', 'restart') -Cmdlet @() -Variable @();
