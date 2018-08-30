[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $True)]
    [string]$ScratchDirectory,
    [Parameter(Mandatory = $True)]
    [ScriptBlock]$FailFastTemplate
)

$Error.Clear();
$FailFast = { & $FailFastTemplate 'https://github.com/icsharpcode/ILSpy/releases/latest' ($args[0]) 'Please install ILSpy yourself.'; };

$response = Invoke-WebRequest 'https://github.com/icsharpcode/ILSpy/releases/latest' -UseBasicParsing;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to retrieve the latest release.';
    Return;
}

$candidates = @($response.Links | Where-Object href -like '*/releases/download/*.zip');
If ($candidates.Count -ne 1)
{
    & $FailFast 'Failed to parse the candidate ZIP.';
}

$zipUri = [uri]::new($response.BaseResponse.ResponseUri, $candidates[0].href).AbsoluteUri.ToString();
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to compose URI.';
    Return;
}

$localPath = [System.IO.Path]::Combine($ScratchDirectory, 'ilspy.zip');
Remove-Item -LiteralPath $localPath -Force -Recurse -ErrorAction Ignore;

Write-Verbose 'Downloading ILSpy binary ZIP...' -Verbose;
[System.Net.WebClient]::new().DownloadFile($zipUri, $localPath);
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to download binary ZIP.';
    Return;
}
Write-Verbose 'Finished downloading.' -Verbose;

$dest = [System.Environment]::GetFolderPath('MyDocuments', 'Create');
$dest = [System.IO.Path]::Combine($dest, 'ILSpy');
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to determine the decompression folder.';
    Return;
}
Expand-Archive -LiteralPath $localPath -DestinationPath $dest -Force;
If ($Error.Count -ne 0)
{
    & $FailFast 'Failed to expand the archive.';
    Return;
}
Invoke-Item -LiteralPath $dest -ErrorAction Ignore;
