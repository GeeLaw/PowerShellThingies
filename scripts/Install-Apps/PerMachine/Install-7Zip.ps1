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
$FailFast = { & $FailFastTemplate 'https://7-zip.org/' ($args[0]) 'Please install 7-Zip yourself.'; };

$response = Invoke-WebRequest 'https://7-zip.org/download.html' -UseBasicParsing;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to retrieve downloads page.';
    Return;
}

$msiRegex = [regex]::new('^.*?7z([0-9]{4,})-x64\.msi$', 'IgnoreCase');
$candidates = @($response.Links | ForEach-Object {
    $candidateMatch = $msiRegex.Match($_.href);
    If ($candidateMatch.Success)
    {
        $_ = $_ | Select-Object href, Version;
        $_.Version = [uint32]::Parse('1' + $candidateMatch.Groups[1].Value);
        $_;
    }
});
If ($candidates.Count -eq 0)
{
    & $FailFast 'Failed to find the candidate package(s).';
    Return;
}
If ($candidates.Count -gt 1)
{
    $verifySuccess = $False
    # Verify that the version descends.
    $candidates | ForEach-Object -Begin { $lastVersion = [uint32]::MaxValue } `
        -Process {
            If ($_.Version -ge $lastVersion)
            {
                Break;
            }
            $lastVersion = $_.Version;
        } -End { $verifySuccess = $True }
    If (-not $verifySuccess)
    {
        & $FailFast '7-Zip did not list the packages in version-descending order.';
        Return;
    }
}

$packageUri = [uri]::new($response.BaseResponse.ResponseUri, $candidates[0].href).AbsoluteUri.ToString();
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to compose URI.';
    Return;
}

$localPath = [System.IO.Path]::Combine($ScratchDirectory, '7z.msi');
Remove-Item -LiteralPath $localPath -Force -Recurse -ErrorAction Ignore;

Start-BitsTransfer -Source $packageUri -Destination $localPath -Description 'Download the latest 7-Zip MSI package for 64-bit Windows.';
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to download the MSI package.';
    Return;
}

$msiExec = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$localPath`" /passive /norestart ALLUSERS=1" -PassThru;
$msiExec.WaitForExit();
If ($msiExec.ExitCode -ne 0)
{
    & $FailFast 'Failed to install 7-Zip MSI package.';
    Return;
}
