[CmdletBinding(SupportsShouldProcess = $True)]
Param ()

Begin
{
    $script:CompanyName = 'BringBackMsft';
    $script:ProductName = 'PhotoViewier';
    $script:AppName = 'Windows Photo Viewer (Resurrected)';
    $script:AppHeadline = 'The good old Windows Photo Viewer.';
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
    If (-not $PSCmdlet.ShouldProcess("Registering file associations with $($AppName):`n`n" + $AssocPromptString,
        "About to register file associations with $($AppName):`n`n" + $AssocPromptString + "`n`nDo you want to continue?",
        'File Association Registration'))
    {
        Break;
    }
    $script:ErrorActionPreference = 'Inquire';
    Push-Location;
    Write-Warning 'If any error happens, remember to Pop-Location.';
    $script:MuiVerb = '@%ProgramFiles%\Windows Photo Viewer\photoviewer.dll,-3043';
    $script:CmdString = '"%SystemRoot%\System32\rundll32.exe" "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1';
    $script:DropTarget = '{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}';
    $script:RegNone = [byte[]]::new(0);
    $script:PInvoke = '[System.Runtime.InteropServices.DllImport("Shell32.dll")] public static extern void SHChangeNotify(int wEventId, uint uFlags, System.UIntPtr dwItem1, System.UIntPtr dwItem2);';
    $script:PInvokeNS = 'PInvoke_23d32a02cf9c4b738171c5784dcf978b';
    $script:PInvokeClass = 'Shell32';
    Write-Verbose 'Preparing P/Invoke.';
    Add-Type -MemberDefinition $PInvoke -Namespace $PInvokeNS -Name $PInvokeClass -ErrorAction 'Ignore' | Out-Null;
    Write-Verbose 'Finished preparing P/Invoke.';
}

Process
{
    Write-Verbose 'Registering application capabilities.';
    Write-Verbose "    Creating HKCU:\Software\$CompanyName\$ProductName\Capabilities.";
    New-Item -Path "HKCU:\Software\$CompanyName\$ProductName\Capabilities" -Force | Set-Location;
    Write-Verbose '    Writing ApplicationName.';
    Set-ItemProperty -LiteralPath '.' -Name 'ApplicationName' -Value $AppName -Force;
    Write-Verbose '    Writing ApplicationDescription.';
    Set-ItemProperty -LiteralPath '.' -Name 'ApplicationDescription' -Value $AppHeadline -Force;
    Write-Verbose '    Writing FileAssociations and MimeAssociations.';
    New-Item -Path '.\FileAssociations' -Force | Out-Null;
    New-Item -Path '.\MimeAssociations' -Force | Out-Null;
    $SupportedTypes | Write-Output -PipelineVariable CurrentType | ForEach-Object {
        $CurrentType.Exts | ForEach-Object {
            Set-ItemProperty -LiteralPath '.\FileAssociations' -Name $_ -Value $CurrentType.ProgId -Force;
        };
        $CurrentType.Mimes | ForEach-Object {
            Set-ItemProperty -LiteralPath '.\MimeAssociations' -Name $_ -Value $CurrentType.ProgId -Force;
        };
    };
    Write-Verbose '    Writing to HKCU:\Software\RegisteredApplications.';
    Set-Location -LiteralPath 'HKCU:\Software';
    If (-not (Test-Path -LiteralPath '.\RegisteredApplications'))
    {
        New-Item -Path '.\RegisteredApplications' -Force | Out-Null;
    }
    Set-ItemProperty -LiteralPath '.\RegisteredApplications' -Name "$CompanyName.$ProductName" -Value "SOFTWARE\$CompanyName\$ProductName\Capabilities" -Force;
    Write-Verbose 'Finished registering application capabilities.';
    # Finished application registration.
    Write-Verbose 'Creating ProgID entries.';
    $SupportedTypes | ForEach-Object {
        Write-Verbose "    Creating ProgID $($_.ProgId).";
        New-Item -Path "HKCU:\Software\Classes\$($_.ProgId)" -Value $_.FriendlyName -Force | Set-Location;
        New-Item -Path '.\DefaultIcon' -Force | Set-Location;
        Set-Item -LiteralPath '.' -Value $_.IconResource -Type 'ExpandString' -Force;
        New-Item -Path '..\shell' -Value 'preview' -Force | Set-Location;
        New-Item -Path '.\preview' -Force | Set-Location;
        Set-ItemProperty -LiteralPath '.' -Name 'MuiVerb' -Value $MuiVerb -Type 'ExpandString' -Force;
        New-Item -Path '.\command' -Force | Set-Location;
        Set-Item -LiteralPath '.' -Type 'ExpandString' -Value $CmdString -Force;
        New-Item -Path '..\DropTarget' -Force | Set-Location;
        Set-ItemProperty -LiteralPath '.' -Name 'Clsid' -Value $DropTarget -Force;
    };
    Write-Verbose 'Finished creating ProgID entries.';
    # Finished ProgID registration.
    Write-Verbose 'Registering OpenWithProgids and taking over the defaults for supported extensions.';
    $SupportedTypes | Write-Output -PipelineVariable CurrentType | ForEach-Object {
        $CurrentType.Exts | ForEach-Object {
            Write-Verbose "    Creating value $($CurrentType.ProgId) in HKCU:\Software\Classes\$_\OpenWithProgids.";
            If (-not (Test-Path -LiteralPath "HKCU:\Software\Classes\$_\OpenWithProgids"))
            {
                New-Item -Path "HKCU:\Software\Classes\$_\OpenWithProgids" -Force | Out-Null;
            }
            Set-Location -LiteralPath "HKCU:\Software\Classes\$_";
            Set-ItemProperty -LiteralPath '.\OpenWithProgids' -Name $CurrentType.ProgId -Value $RegNone -Type 'None' -Force;
            Write-Verbose "    Setting $($CurrentType.ProgId) as the default value of HKCU:\Software\Classes\$_.";
            Set-Item -LiteralPath '.' -Value $CurrentType.ProgId -Force;
        };
    };
    Write-Verbose 'Finished registering OpenWithProgids.';
    Write-Verbose 'Calling SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST | SHCNF_FLUSH, NULL, NULL).';
    [PInvoke_23d32a02cf9c4b738171c5784dcf978b.Shell32]::SHChangeNotify(0x8000000, 0x1000, [System.UIntPtr]::Zero, [System.UIntPtr]::Zero);
    Write-Verbose 'SHChangeNotify returned.';
    Write-Verbose 'Finished file association registration.';
}

End
{
    Pop-Location;
}
