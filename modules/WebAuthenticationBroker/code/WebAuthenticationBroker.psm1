<#
.SYNOPSIS
    Displays an interactive UI to authenticate the user against some Web service.

.DESCRIPTION
    The Request-WebAuthentication advanced function displays an interactive UI to authenticate the user against some Web service. The UI used depends on the platform and can be tuned with parameters.

On Windows, it displays a window with web browser control inside by default.

    On other platforms, it uses Start-Process to open the initial web page, then invokes the host UI to get the result. If NoGui parameter is switched on, the advanced function takes this path even if it is running on Windows.

.PARAMETER InitialUri
    Specifies the initial URI to open. It must start with "http://" or "https://".

    GUI  on: the page is opened inside a window.
    GUI off: it is handled by Start-Process.

.PARAMETER CompletionExtractor
    Specifies the completion extractor. The extractor should consume the URI using the pipeline variable $_, and should either return nothing (or $null), or something.

    GUI  on: the extractor is called AFTER each navigation of the hosted web browser.
    GUI off: it is called after the user pastes the final URI into the host. See UriPredicate parameter for more on GUI-disabled situation.

    The extractor returning nothing (or $null) means no authentication information is extracted from the URI.
    - GUI  on: this means the GUI continues to wait for user interaction.
    - GUI off: authentication fails.

    The extractor returning something (other than $null) means some implementation-specific information has been extracted. Whatever returned by the extractor is written downstream in the pipeline, i.e., returned by the Request-WebAuthentication advanced function.
    - GUI  on: the GUI is dismissed and control is returned to PowerShell scripts for further processing.

    It is advised to return information as soon as there is some result. Even if the result is failed authentication.
    - GUI  on: the window does not automatically dismiss itself until CompletionExtractor returns non-$null, and you should return non-$null if you can extract a failure from the URI, and add your error handling logic after the call to Request-WebAuthentication has returned.
    - GUI off: it is okay to return $null if the URI contains an authentication failure, since it will never confuse the user. If you go for this scenario, you should always explicitly specify NoGui switch. However, it is stongly advised that you unify the two scenarios. Think the completion extractor as what is indicated by its name -- it finds when the authentication procedure has completed, not when the authentication procedure has succeeded.

.PARAMETER UriPredicate
    Optionally specifies the URI predicate. The predicate should consume the URI using the pipeline variable $_, and should either return $True or $False.

    GUI  on: the predicate is called BEFORE each navigation of the hosted web browser.
    GUI off: it is called after the user pastes the final URI into the host.

    The predicate returning $True means the URI is allowed.
    - GUI  on: this means the navigation will happen.
    - GUI off: this means processing can proceed.

    The predicate returning $False means the URI is disallowed.
    - GUI  on: this means the navigation is cancelled, and the user stays on the last page.
    - GUI off: this means processing is stopped.

    If UriPredicate returns $False, the user will not succeed authentication, regardless of whether GUI is on or off. Specifically, if GUI is off, this predicate is checked before the extractor can be called.

    One possible usage of this parameter is to prevent insecure pages when GUI is on. Note that if GUI is off, it is not guaranteed that the user not visit HTTP pages in-between, as only what is pasted into the host is checked.

.PARAMETER Title
    Optionally specifies a title for the UI. If not provided, it falls back to a generic title.

    GUI  on: this becomes the title of the authnetication broker window.
    GUI off: this is handed to the host. PowerShell host displays the title before the prompt.

.PARAMETER TitleIsUri
    Sets the current URI as the title.

    GUI  on: Title parameter, if set, is ignored, and the window title will always be the current URI.
    GUI off: this parameter is ignored, and Title parameter is used.

.PARAMETER Prompt
    Optionally specifies a prompt for the UI. If not provided, it falls back to a generic prompt.

    GUI  on: this parameter is ignored.
    GUI off: this parameter is handed to the host. PowerShell host displays the prompt after the title.

.PARAMETER ErrorHandling
    Optionally specifies how the advanced function responds to authentication failures. Possible values are the following:

    - Silent: simply returns nothing upon failure.
    - Write: uses $PSCmdlet.ThrowTerminatingError and returns nothing upon failure.
    - Throw (default): uses Throw keyword, which causes whatever follows the call to be aborted, until the thrown error record is caught by some surrounding Try-Catch(-Finally) block.

    Note that even if the advanced function returns something, authentication might have failed. It just means CompletionExtractor has told the advanced function to proceed.

.PARAMETER NoGui
    Prevents the advanced function from using GUI, and always makes it fall back to host-provided UI.

    By default, the advanced function uses a window with hosted web browser on Windows.

    In PowerShell for Windows, if this switch is on, InitialUri is opened with the user's default web browser (HTTP/HTTPS URI protocol handler), and the user needs to paste the URI into the host after authentication to proceed.

    In PowerShell Core, this switch is currently ignored.

.OUTPUTS
    Whatever is returned by the last call to CompletionExtractor.

.EXAMPLE
    Write-Verbose 'Authenticating against Microsoft online services.';

    $CLIENT_ID = 'your client id';
    $REDIRECT_URI = 'https://login.microsoftonline.com/common/oauth2/nativeclient';
    $REQUESTED_SCOPES = 'scopes to request';

    $authUri = 'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
    $authUri += "?client_id=$([uri]::EscapeDataString($CLIENT_ID))";
    $authUri += '&response_type=code';
    $authUri += "&redirect_uri=$([uri]::EscapeDataString($REDIRECT_URI))";
    $authUri += "&scope=$([uri]::EscapeDataString($REQUESTED_SCOPES))";

    $result = Request-WebAuthentication -InitialUri $authUri `
        -CompletionExtractor {
        If ($_.ToLowerInvariant().StartsWith($REDIRECT_URI + '?'))
        {
            Return ($_.Substring($REDIRECT_URI.Length + 1));
        }
    } -Title 'Sign in with your Micorosft account or Azure AD account';
    $result = "&$result&";

    $errMatch = ([regex]'&[eE][rR][rR][oO][rR]=(.*?)&').Match($result);
    If ($errMatch.Success)
    {
        Throw ("Authentication failed: " +
            [uri]::UnescapeDataString($errMatch.Groups[1].Value));
    }

    $codeMatch = ([regex]'&[cC][oO][dD][eE]=(.*?)&').Match($result);
    If (-not $codeMatch.Success)
    {
        Throw "Result URI does not contain code.";
    }

    $code = [uri]::UnescapeDataString($codeMatch.Groups[1].Value);
    Write-Verbose "Acquired code: $code";

    This example tries to authenticate the user against Microsoft services (e.g. Microsoft account and/or Azure AD accounts when using Microsoft Graph API). In PowerShell for Windows, the user is presented with a window with a hosted web browser inside. In PowerShell Core, the user has to paste the URI into the host. After the GUI/CLI is dismissed (completed or cancelled), the script proceeds to extract the code from the result URI. If the call to Request-WebAuthentication fails, the whole script will be aborted, which prevents errneous processing. If recovery is required, wrap the block with Try-Catch(-Finally).

.LINK
    https://github.com/GeeLaw/PowerShellThingies/blob/master/modules/WebAuthenticationBroker

#>
Function Request-WebAuthentication
{
    [CmdletBinding(PositionalBinding = $False)]
    Param
    (
        [Parameter(Mandatory = $True)]
        [ValidateScript({
            If ([string]::IsNullOrWhiteSpace($_))
            {
                Throw 'InitialUri must be non-whitespace.';
                Return $False;
            }
            ElseIf (-not $_.ToLowerInvariant().StartsWith('http://') -and -not $_.ToLowerInvariant().StartsWith('https://'))
            {
                Throw 'InitialUri must be a valid absolute Uri of HTTP or HTTPS protocol.';
                Return $False;
            }
            Else
            {
                Return $True;
            }
        })]
        [string]$InitialUri,
        [Parameter(Mandatory = $True)]
        [ValidateNotNull()]
        [ScriptBlock]$CompletionExtractor,
        [Parameter(Mandatory = $False)]
        [ValidateNotNull()]
        [ScriptBlock]$UriPredicate = { $True },
        [Parameter(Mandatory = $False)]
        [ValidateScript({
            If ([string]::IsNullOrWhiteSpace($_))
            {
                Throw 'Title must be non-whitespace.';
                Return $False;
            }
            Else
            {
                Return $True;
            }
        })]
        [string]$Title = 'PowerShell Web Authentication Broker',
        [Parameter(Mandatory = $False)]
        [switch]$TitleIsUri,
        [Parameter(Mandatory = $False)]
        [ValidateScript({
            If ([string]::IsNullOrWhiteSpace($_))
            {
                Throw 'Prompt must be non-whitespace.';
            }
        })]
        [string]$Prompt = 'Copy the URI after authentication, and paste it here (empty to cancel).',
        [Parameter(Mandatory = $False)]
        [ValidateSet('Silent', 'Write', 'Throw')]
        [string]$ErrorHandling = 'Throw',
        [Parameter(Mandatory = $False)]
        [switch]$NoGui
    )
    Begin
    {
        [System.Management.Automation.ErrorRecord]$local:errorRecord = $null;
        [ScriptBlock]$local:errorHandler = $null;
        $ErrorHandling = $ErrorHandling.ToLowerInvariant();
        If ($ErrorHandling -eq 'throw')
        {
            $errorHandler = { Throw $errorRecord; };
        }
        ElseIf ($ErrorHandling -eq 'write')
        {
            $errorHandler = { $PSCmdlet.ThrowTerminatingError($errorRecord); };
        }
        Else
        {
            $errorHandler = { };
        }
        [ScriptBlock]$local:runBroker = {
            Start-Process -FilePath $InitialUri | Out-Null;
            $local:askCollection = [System.Collections.ObjectModel.Collection[System.Management.Automation.Host.FieldDescription]]::new();
            $askCollection.Add([System.Management.Automation.Host.FieldDescription]::new('Uri'));
            $local:askResult = $Host.UI.Prompt($Title, $Prompt, $askCollection);
            [string]$local:resultUri = $askResult['Uri'];
            If ([string]::IsNullOrWhiteSpace($resultUri))
            {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new('The user cancelled the operation.'),
                    'User-Cancel',
                    [System.Management.Automation.ErrorCategory]::OperationStopped,
                    $null);
                & $errorHandler;
                Return;
            }
            $resultUri = $resultUri.Trim();
            [bool]$local:predicateResult = $local:resultUri | ForEach-Object -Process $UriPredicate;
            If (-not $predicateResult)
            {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new('UriPredicate declined the URI: ' + $resultUri),
                    'UriPredicate-Decline',
                    [System.Management.Automation.ErrorCategory]::InvalidResult,
                    $resultUri);
                & $errorHandler;
                Return;
            }
            [object]$local:extractionResult = $local:resultUri | ForEach-Object -Process $CompletionExtractor;
            If ($extractionResult -eq $null)
            {
                $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                    [System.Exception]::new('CompletionExtractor could not recognize the URI: ' + $resultUri),
                    'CompletionExtractor-NoResult',
                    [System.Management.Automation.ErrorCategory]::InvalidResult,
                    $resultUri);
                & $errorHandler;
                Break;
            }
            Return $extractionResult;
        };
    }
    Process
    {
        [object]$local:brokerWindow = $null;
        Try
        {
            If (-not $NoGui)
            {
                $brokerWindow = [PSWebAuthBroker_ab8baa5cebae4693a6fc517d7b0f69c3.BrokerWindow]::new();
            }
        }
        Catch
        {
            $brokerWindow = $null;
        }
        If ($brokerWindow -ne $null)
        {
            $brokerWindow.Title = $Title;
            $brokerWindow.InitialUri = $InitialUri;
            $brokerWindow.CompletionExtractor = [System.Func[string, object]]{ Return ($args | ForEach-Object -Process $CompletionExtractor); };
            $brokerWindow.UriPredicate = [System.Func[string, bool]]{ Return ($args | ForEach-Object -Process $UriPredicate); };
            $runBroker = {
                If (-not $brokerWindow.AuthenticateUser())
                {
                    $errorRecord = [System.Management.Automation.ErrorRecord]::new(
                        [System.Exception]::new('The user cancelled the operation.'),
                        'User-Cancel',
                        [System.Management.Automation.ErrorCategory]::OperationStopped,
                        $null);
                    & $errorHandler;
                    Return;
                }
                [object]$local:extractionResult = $brokerWindow.Extracted;
                Return $extractionResult;
            };
        }
        & $runBroker;
    }
}

Export-ModuleMember -Function @('Request-WebAuthentication');
