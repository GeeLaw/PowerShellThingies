[CmdletBinding(SupportsShouldProcess=$True)]
Param
(
    [switch]$Undo
)

Begin
{
    $script:MediaExtensions = @('.dvr-ms', '.wtv', '.3g2', '.3gp', '.3gp2', '.3gpp', '.aac', '.adt', '.adts', '.aif', '.aifc', '.aiff', '.asf', '.au', '.avi', '.m1v', '.m2t', '.m2ts', '.m2v', '.m4a', '.m4v', '.mid', '.midi', '.mod', '.mp2', '.mp2v', '.mp3', '.mp4', '.mp4v', '.mpa', '.mpe', '.mpeg', '.mpg', '.mpv2', '.mts', '.rmi', '.snd', '.ts', '.tts', '.wav', '.wm', '.wma', '.wmv');
    $script:HandlerCLSID = '{031EE060-67BC-460d-8847-E4A7C5E45A27}';
    $script:HandlerIID = '{8895b1c6-b41f-4c1c-a562-0d564250836f}';
    If ($Undo)
    {
        If (-not $PSCmdlet.ShouldProcess('Removing the preview handlers of these extensions (whether or not they are Windows Media Player): ' + ($MediaExtensions -join ' '),
            'About to remove the preview handlers of these extensions (whether or not they are Windows Media Player): ' + ($MediaExtensions -join ' '),
            'Removing preview handler'))
        {
            Break
        }
    }
    Else
    {
        If (-not $PSCmdlet.ShouldProcess('Setting the preview handler of these extensions to Windows Media Player: ' + ($MediaExtensions -join ' '),
            'About to set the preview handler of these extensions to Windows Media Player: ' + ($MediaExtensions -join ' ') + "`n`nDo you want to continue?",
            'Setting preview handler'))
        {
            Break
        }
    }
    $script:PInvoke = '[System.Runtime.InteropServices.DllImport("Shell32.dll")] public static extern void SHChangeNotify(int wEventId, uint uFlags, System.UIntPtr dwItem1, System.UIntPtr dwItem2);';
    $script:PInvokeNS = 'PInvoke_23d32a02cf9c4b738171c5784dcf978b';
    $script:PInvokeClass = 'Shell32';
    Write-Verbose 'Preparing P/Invoke.';
    Add-Type -MemberDefinition $PInvoke -Namespace $PInvokeNS -Name $PInvokeClass -ErrorAction 'Ignore' | Out-Null;
    Write-Verbose 'Finished preparing P/Invoke.';
}

Process
{
    If ($Undo)
    {
        $MediaExtensions | ForEach-Object {
            Remove-Item -LiteralPath "HKCU:\Software\Classes\$_\shellex\$HandlerIID" -Recurse -Force;
        };
    }
    Else
    {
        $MediaExtensions | ForEach-Object {
            New-Item -Path "HKCU:\Software\Classes\$_\shellex\$HandlerIID" -Force -Value $HandlerCLSID | Out-Null;
        };
    }
}

End
{
    Write-Verbose 'Calling SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST | SHCNF_FLUSH, NULL, NULL).';
    [PInvoke_23d32a02cf9c4b738171c5784dcf978b.Shell32]::SHChangeNotify(0x8000000, 0x1000, [System.UIntPtr]::Zero, [System.UIntPtr]::Zero);
    Write-Verbose 'SHChangeNotify returned.';
    Write-Verbose 'Finished media file preview handler manipulation.';
}
