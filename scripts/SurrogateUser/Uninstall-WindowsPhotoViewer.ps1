[CmdletBinding(SupportsShouldProcess = $True)]
Param ()

Begin
{
    $script:SupportedExts = @('.bmp', '.dib', '.emf', '.gif', '.ico', '.jfif', '.jpe', '.jpeg', '.jpg', '.png', '.rle', '.tif', '.tiff', '.wmf');
    $script:SupportedMimes = @('image/bmp', 'image/x-emf', 'image/gif', 'image/x-icon', 'image/jpeg', 'image/png', 'image/tiff', 'image/x-wmf');
    If (-not $PSCmdlet.ShouldProcess("UNregistering the file association of Windows Photo Viewer`nfor extensions:`n" + ($SupportedExts -join '/') + "`nand for MIME types:`n" + ($SupportedMimes -join ', ') + '.',
        "About to UNregister the file association of Windows Photo Viewer`n`nfor extensions:`n" + ($SupportedExts -join '/') + "`n`nand for MIME types:`n" + ($SupportedMimes -join ', ') + ".`n`nDo you want to continue?",
        'File Association DEregistration'))
    {
        Break;
    }
    $script:ErrorActionPreference = 'Inquire';
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
    Write-Verbose 'Unregistering application capabilities.';
    If (-not (Test-Path -LiteralPath "HKCU:\Software\$CompanyName\$ProductName"))
    {
        Write-Verbose "    HKCU:\Software\$CompanyName\$ProductName does not exist.";
    }
    Else
    {
        Write-Verbose "    Deleting HKCU:\Software\$CompanyName\$ProductName.";
        Remove-Item -LiteralPath "HKCU:\Software\$CompanyName\$ProductName" -Force -Recurse;
        Write-Verbose '    Deleted.';
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
        Write-Verbose "    Deleting value $CompanyName.$ProductName from HKCU:\Software\RegisteredApplications.";
        Remove-ItemProperty -LiteralPath 'HKCU:\Software\RegisteredApplications' -Name "$CompanyName.$ProductName" -Force;
        Write-Verbose '    Deleted.';
    }
    Write-Verbose 'Finished unregistering application capabilities.';
    Write-Verbose 'Removing ProgID entry.';
    If (-not (Test-Path -LiteralPath "HKCU:\Software\Classes\$CompanyName.$ProductName.$FileName"))
    {
        Write-Verbose "    HKCU:\Software\Classes\$CompanyName.$ProductName.$FileName (ProgID) does not exist.";
    }
    Else
    {
        Write-Verbose "    Deleting HKCU:\Software\Classes\$CompanyName.$ProductName.$FileName (ProgID entry).";
        Remove-Item -LiteralPath "HKCU:\Software\Classes\$CompanyName.$ProductName.$FileName" -Force -Recurse;
        Write-Verbose '    Deleted.';
    }
    Write-Verbose 'Finished removing ProgID entry.';
    Write-Verbose 'Calling SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST | SHCNF_FLUSH, NULL, NULL).';
    [PInvoke_23d32a02cf9c4b738171c5784dcf978b.Shell32]::SHChangeNotify(0x8000000, 0x1000, [System.UIntPtr]::Zero, [System.UIntPtr]::Zero);
    Write-Verbose 'SHChangeNotify returned.';
    Write-Verbose 'Finished file association deregistration.';
}

End
{
}
