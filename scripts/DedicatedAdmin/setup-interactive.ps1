<# Sysinternals and VSCode #>
& {

[System.Net.ServicePointManager]::SecurityProtocol = 'Ssl3, Tls, Tls11, Tls12';

$FFTplt = {
    Start-Process ($args[0]);
    $args | Select-Object -Skip 1 | Write-Host -BackgroundColor Black -ForegroundColor Red;
    Pause;
    $Error.Clear();
}

$installSysinternals = [System.IO.Path]::Combine($PSScriptRoot, '..', 'Install-Apps', 'PerUser', 'Install-Sysinternals.ps1');
$tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString('n'));
New-Item -Path $tempDir -ItemType 'Directory' -Force;
& $installSysinternals -ScratchDirectory $tempDir -FailFastTemplate $FFTplt;

$installVSCode = [System.IO.Path]::Combine($PSScriptRoot, '..', 'Install-Apps', 'PerUser', 'Install-VSCode.ps1');
$tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString('n'));
New-Item -Path $tempDir -ItemType 'Directory' -Force;
& $installVSCode -ScratchDirectory $tempDir -FailFastTemplate $FFTplt;

} | Out-Null;

<# Theming #>
& {

Invoke-Item -LiteralPath ([System.IO.Path]::Combine([System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Windows), 'Resources', 'Themes', 'aero.theme')) -ErrorAction 'Ignore';

} | Out-Null;
