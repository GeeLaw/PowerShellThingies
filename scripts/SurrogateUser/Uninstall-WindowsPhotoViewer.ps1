[CmdletBinding(SupportsShouldProcess = $True)]
Param ()

Begin
{
    $script:CompanyName = 'BringBackMsft';
    $script:ProductName = 'PhotoViewier';
    $script:AppName = 'Windows Photo Viewer (Resurrected)';
    $script:SupportedTypes = @(
        @{ 'ProgIdSuffix' = 'bmp';
           'FriendlyName' = 'Bitmap Image';
           'Exts' = @('.bmp');
           'Mimes' = @('image/bmp');
           'IconResource' = '%systemroot%\system32\imageres.dll,-70' },
        @{ 'ProgIdSuffix' = 'dib';
           'FriendlyName' = 'Device-Independent Bitmap Image';
           'Exts' = @('.dib');
           'Mimes' = @();
           'IconResource' = '%systemroot%\system32\imageres.dll,-70' },
        @{ 'ProgIdSuffix' = 'emf';
           'FriendlyName' = 'Enhanced Windows Metafile Image';
           'Exts' = @('.emf');
           'Mimes' = @('image/emf', 'image/x-emf');
           'IconResource' = '%SystemRoot%\system32\mspaint.exe,-3' },
        @{ 'ProgIdSuffix' = 'gif';
           'FriendlyName' = 'Graphics Interchange Format Image';
           'Exts' = @('.gif');
           'Mimes' = @('image/gif');
           'IconResource' = '%SystemRoot%\System32\imageres.dll,-71' },
        @{ 'ProgIdSuffix' = 'ico';
           'FriendlyName' = 'Icon';
           'Exts' = @('.ico');
           'Mimes' = @('image/x-icon');
           'IconResource' = '%1' },
        @{ 'ProgIdSuffix' = 'pjpeg';
           'FriendlyName' = 'JPEG File Interchange Format Image';
           'Exts' = @('.jfif');
           'Mimes' = @();
           'IconResource' = '%SystemRoot%\System32\imageres.dll,-72' },
        @{ 'ProgIdSuffix' = 'jpeg';
           'FriendlyName' = 'Joint Photographic Experts Group Image';
           'Exts' = @('.jpe', '.jpeg', '.jpg');
           'Mimes' = @('image/jpeg');
           'IconResource' = '%SystemRoot%\System32\imageres.dll,-72' },
        @{ 'ProgIdSuffix' = 'png';
           'FriendlyName' = 'Portable Network Graphics Image';
           'Exts' = @('.png');
           'Mimes' = @('image/png');
           'IconResource' = '%SystemRoot%\System32\imageres.dll,-83' },
        @{ 'ProgIdSuffix' = 'rle';
           'FriendlyName' = 'Run-Length Encoded Image';
           'Exts' = @('.rle');
           'Mimes' = @();
           'IconResource' = '%SystemRoot%\system32\mspaint.exe,-3' },
        @{ 'ProgIdSuffix' = 'tiff';
           'FriendlyName' = 'Tag Image File Format Image';
           'Exts' = @('.tif', '.tiff');
           'Mimes' = @('image/tiff');
           'IconResource' = '%SystemRoot%\System32\imageres.dll,-122' },
        @{ 'ProgIdSuffix' = 'wmf';
           'FriendlyName' = 'Windows Metafile Image';
           'Exts' = @('.wmf');
           'Mimes' = @('image/wmf', 'image/x-wmf');
           'IconResource' = '%SystemRoot%\system32\mspaint.exe,-3' }
    ) | ForEach-Object {
        $_['FileTypes'] = $_['Exts'] + $_['Mimes'];
        $_['ProgId'] = $CompanyName + '.' + $ProductName + '.' + $_['ProgIdSuffix'];
        [pscustomobject]$_;
    } | Where-Object -Property 'ProgIdSuffix' -in @('bmp', 'dib', 'gif', 'ico', 'pjpeg', 'jpeg', 'png');
    $script:AssocPromptString = $SupportedTypes | Format-Table -Property ProgId, FileTypes -AutoSize | Out-String;
    If (-not $PSCmdlet.ShouldProcess("UNregistering file associations with $($AppName):`n`n" + $AssocPromptString,
        "About to UNregister file associations with $($AppName):`n`n" + $AssocPromptString + "`n`nDo you want to continue?",
        'File Association DERegistration'))
    {
        Break;
    }
    $script:ErrorActionPreference = 'Inquire';
    $script:PInvoke = '[System.Runtime.InteropServices.DllImport("Shell32.dll")] public static extern void SHChangeNotify(int wEventId, uint uFlags, System.UIntPtr dwItem1, System.UIntPtr dwItem2);';
    $script:PInvokeNS = 'PInvoke_23d32a02cf9c4b738171c5784dcf978b';
    $script:PInvokeClass = 'Shell32';
    Write-Verbose 'Preparing P/Invoke.';
    Add-Type -MemberDefinition $PInvoke -Namespace $PInvokeNS -Name $PInvokeClass -ErrorAction 'Ignore' | Out-Null;
    Write-Verbose 'Finished preparing P/Invoke.';
}

Process
{
    Write-Verbose 'Unregistering application capabilities.';
    If (-not (Test-Path -LiteralPath "HKCU:\Software\$CompanyName\$ProductName"))
    {
        Write-Verbose "    HKCU:\Software\$CompanyName\$ProductName does not exist.";
    }
    Else
    {
        Write-Verbose "    Removing HKCU:\Software\$CompanyName\$ProductName.";
        Remove-Item -LiteralPath "HKCU:\Software\$CompanyName\$ProductName" -Force -Recurse;
    }
    If (-not (Test-Path -LiteralPath 'HKCU:\Software\RegisteredApplications'))
    {
        Write-Verbose '    HKCU:\Software\RegisteredApplications does not exist.';
    }
    ElseIf ((Get-Item -LiteralPath 'HKCU:\Software\RegisteredApplications').Property -notcontains "$CompanyName.$ProductName")
    {
        Write-Verbose "    $CompanyName.$ProductName is not registered in HKCU:\Software\RegisteredApplications.";
    }
    Else
    {
        Write-Verbose "    Removing value $CompanyName.$ProductName from HKCU:\Software\RegisteredApplications.";
        Remove-ItemProperty -LiteralPath 'HKCU:\Software\RegisteredApplications' -Name "$CompanyName.$ProductName" -Force;
    }
    Write-Verbose 'Finished unregistering application capabilities.';
    Write-Verbose 'Removing ProgID entries.';
    $SupportedTypes | Write-Output -PipelineVariable CurrentType | ForEach-Object {
        If (-not (Test-Path -LiteralPath "HKCU:\Software\Classes\$($_.ProgId)"))
        {
            Write-Verbose "    HKCU:\Software\Classes\$($CurrentType.ProgId) does not exist.";
        }
        Else
        {
            Write-Verbose "    Removing HKCU:\Software\Classes\$($CurrentType.ProgId).";
            Remove-Item -LiteralPath "HKCU:\Software\Classes\$($CurrentType.ProgId)" -Force -Recurse;
        }
        $_.Exts | ForEach-Object {
            Write-Verbose "    Removing value $($CurrentType.ProgId) in HKCU:\Software\Classes\$_\OpenWithProgids.";
            Remove-ItemProperty -LiteralPath "HKCU:\Software\Classes\$_\OpenWithProgids" -Name $CurrentType.ProgId -Force -ErrorAction 'Ignore';
        };
    };
    Write-Verbose 'Finished removing ProgID entries.';
    Write-Verbose 'Calling SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST | SHCNF_FLUSH, NULL, NULL).';
    [PInvoke_23d32a02cf9c4b738171c5784dcf978b.Shell32]::SHChangeNotify(0x8000000, 0x1000, [System.UIntPtr]::Zero, [System.UIntPtr]::Zero);
    Write-Verbose 'SHChangeNotify returned.';
    Write-Verbose 'Finished file association deregistration.';
}

End
{
}
