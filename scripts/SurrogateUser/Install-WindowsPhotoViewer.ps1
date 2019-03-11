[CmdletBinding(SupportsShouldProcess = $True)]
Param ()

Begin
{
    $script:SupportedExts = @('.bmp', '.dib', '.emf', '.gif', '.ico', '.jfif', '.jpe', '.jpeg', '.jpg', '.png', '.rle', '.tif', '.tiff', '.wmf');
    $script:SupportedMimes = @('image/bmp', 'image/x-emf', 'image/gif', 'image/x-icon', 'image/jpeg', 'image/png', 'image/tiff', 'image/x-wmf');
    If (-not $PSCmdlet.ShouldProcess("Registering the file association of Windows Photo Viewer`nfor extensions:`n" + ($SupportedExts -join '/') + "`nand for MIME types:`n" + ($SupportedMimes -join ', ') + '.',
        "About to register the file association of Windows Photo Viewer`n`nfor extensions:`n" + ($SupportedExts -join '/') + "`n`nand for MIME types:`n" + ($SupportedMimes -join ', ') + ".`n`nDo you want to continue?",
        'File Association Registration'))
    {
        Break;
    }
    $script:ErrorActionPreference = 'Inquire';
    Push-Location;
    Write-Warning 'If any error happens, remember to Pop-Location.';
    $script:CompanyName = 'BringBackMsft';
    $script:ProductName = 'PhotoViewier';
    $script:FileName = 'File';
    $script:AppName = 'Windows Photo Viewer';
    $script:AppHeadline = 'The good old Windows Photo Viewer.';
    $script:FriendlyFileType = 'Photo file';
    $script:IconResource = '%SystemRoot%\SHELL32.dll,324';
    $script:MuiVerb = '@%ProgramFiles%\Windows Photo Viewer\photoviewer.dll,-3043';
    $script:CmdString = '"%SystemRoot%\System32\rundll32.exe" "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1';
    $script:DropTarget = '{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}';
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
    Write-Verbose '    Writing FileAssociations.';
    New-Item -Path '.\FileAssociations' -Force | Set-Location;
    $SupportedExts | ForEach-Object {
        Set-ItemProperty -LiteralPath '.' -Name $_ -Value "$CompanyName.$ProductName.$FileName" -Force;
    };
    Write-Verbose '    Writing MimeAssociations.';
    New-Item -Path '..\MimeAssociations' -Force | Set-Location;
    $SupportedMimes | ForEach-Object {
        Set-ItemProperty -LiteralPath '.' -Name $_ -Value "$CompanyName.$ProductName.$FileName" -Force;
    };
    Write-Verbose '    Writing to HKCU:\Software\RegisteredApplications.';
    Set-Location -LiteralPath 'HKCU:\Software';
    If (-not (Test-Path -LiteralPath '.\RegisteredApplications'))
    {
        New-Item -Path '.\RegisteredApplications' -Force | Out-Null;
    }
    Set-ItemProperty -LiteralPath '.\RegisteredApplications' -Name "$CompanyName.$ProductName" -Value "SOFTWARE\$CompanyName\$ProductName\Capabilities" -Force;
    Write-Verbose 'Finished application capability registration.';
    # Finished application registration.
    Write-Verbose 'Creating ProgID.';
    New-Item -Path "HKCU:\Software\Classes\$CompanyName.$ProductName.$FileName" -Value $AppName -Force | Set-Location;
    New-Item -Path '.\DefaultIcon' -Force | Set-Location;
    Set-Item -LiteralPath '.' -Value $IconResource -Type 'ExpandString' -Force;
    New-Item -Path '..\shell' -Value 'preview' -Force | Set-Location;
    New-Item -Path '.\preview' -Force | Set-Location;
    Set-ItemProperty -LiteralPath '.' -Name 'MuiVerb' -Value $MuiVerb -Type 'ExpandString' -Force;
    New-Item -Path '.\command' -Force | Set-Location;
    Set-Item -LiteralPath '.' -Type 'ExpandString' -Value $CmdString -Force;
    New-Item -Path '..\DropTarget' -Force | Set-Location;
    Set-ItemProperty -LiteralPath '.' -Name 'Clsid' -Value $DropTarget -Force;
    Write-Verbose 'Finished ProgID creation.';
    # Finished ProgID registration.
    Write-Verbose 'Registering OpenWithProgids and taking over the defaults for supported file types.';
    $SupportedExts + @('SystemFileAssociations\image') | ForEach-Object {
        If (-not (Test-Path -LiteralPath "HKCU:\Software\Classes\$_\OpenWithProgids"))
        {
            New-Item -Path "HKCU:\Software\Classes\$_\OpenWithProgids" -Force | Out-Null;
        }
        Set-Location -LiteralPath "HKCU:\Software\Classes\$_";
        Set-ItemProperty -LiteralPath '.\OpenWithProgids' -Name "$CompanyName.$ProductName.$FileName" -Value '' -Force;
        Set-Item -LiteralPath '.' -Value "$CompanyName.$ProductName.$FileName" -Force;
    };
    Write-Verbose 'Finished registry operation.';
    Write-Verbose 'Calling SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST | SHCNF_FLUSH, NULL, NULL).';
    [PInvoke_23d32a02cf9c4b738171c5784dcf978b.Shell32]::SHChangeNotify(0x8000000, 0x1000, [System.UIntPtr]::Zero, [System.UIntPtr]::Zero);
    Write-Verbose 'SHChangeNotify returned.';
    Write-Verbose 'Finished file association registration.';
}

End
{
    Pop-Location;
}
