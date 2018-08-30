#Requires -RunAsAdministrator

[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $True)]
    [string]$ScratchDirectory,
    [Parameter(Mandatory = $True)]
    [ScriptBlock]$FailFastTemplate
)

$Error.Clear();
$FailFast = { & $FailFastTemplate 'https://www.microsoft.com/en-us/download/details.aspx?id=52459' ($args[0]) 'Please install Image Composite Editor yourself.'; };

$response = Invoke-WebRequest 'https://www.microsoft.com/en-us/download/confirmation.aspx?id=52459' -UseBasicParsing;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to retrieve candidates.';
    Return;
}

$candidates = @($response.Links | Where-Object href -like '*.msi' | ForEach-Object {
    $resolvedHref = [uri]::new($response.BaseResponse.ResponseUri, $_.href).AbsoluteUri.ToString();
    $_ | Add-Member -MemberType NoteProperty -Name 'href@resolved' -Value $resolvedHref -PassThru;
} | Group-Object 'href@resolved');
If ($candidates.Count -ne 1)
{
    & $FailFast 'Failed to determine MSI package URI.';
    Return;
}

$packageUri = $candidates[0].Name;

$localPath = [System.IO.Path]::Combine($ScratchDirectory, 'ice-x64.msi');
Remove-Item -LiteralPath $localPath -Force -Recurse -ErrorAction Ignore;

Start-BitsTransfer -Source $packageUri -Destination $localPath -Description 'Download Image Composite Editor (x64).';
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to download the MSI package.';
    Return;
}

$msiExec = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$localPath`" /passive /norestart ALLUSERS=1 ADDLOCAL=ALL" -PassThru;
$msiExec.WaitForExit();
If ($msiExec.ExitCode -ne 0)
{
    & $FailFast 'Failed to install Image Composite Editor MSI package.';
    Return;
}
