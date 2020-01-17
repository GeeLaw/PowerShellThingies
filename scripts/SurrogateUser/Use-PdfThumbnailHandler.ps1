[CmdletBinding(SupportsShouldProcess=$True)]
Param
(
    [switch]$Undo,
    [switch]$Force
)

Begin
{
    If ($Undo)
    {
        If (-not $PSCmdlet.ShouldProcess('Removing the thumbnail handler for ".pdf" (but not any class that could be associated with ".pdf").',
            'About to remove the thumbnail handler of ".pdf" (but not any class that could be associated with ".pdf").' + "`n`nDo you want to continue?",
            'Removing thumbnail handler'))
        {
            Break
        }
    }
    Else
    {
        If (-not $PSCmdlet.ShouldProcess('Setting the thumbnail handler of ".pdf" to Adobe Reader DC. This allows you to get thumbnails even if you have associated ".pdf" to other readers (e.g., Microsoft Edge or MiKTeX).',
            'About to set the thumbnail handler of ".pdf" to Adobe Reader DC. This allows you to get thumbnails even if you have associated ".pdf" to other readers (e.g., Microsoft Edge or MiKTeX).' + "`n`nDo you want to continue?",
            'Setting thumbnail handler'))
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
        If (-not $Force)
        {
            Write-Warning 'This will remove the thumbnail handler associated to ".pdf" even if if was not created by this script.' -WarningAction 'Inquire';
        }
        Remove-Item -LiteralPath 'HKCU:\Software\Classes\.pdf\shellex\{BB2E617C-0920-11d1-9A0B-00C04FC2D6C1}' -Recurse -Force;
    }
    Else
    {
        If (-not $Force)
        {
            Write-Warning 'This will work only if you have installed Adobe Reader DC. Moreover, this is not fully tested or guaranteed to be future-compatible. Proceed at your own risk and undo the changes if necessary.' -WarningAction 'Inquire';
        }
        New-Item -Path 'HKCU:\Software\Classes\.pdf\shellex\{BB2E617C-0920-11d1-9A0B-00C04FC2D6C1}' -Force -Value '{F9DB5320-233E-11D1-9F84-707F02C10627}' | Out-Null;
    }
}

End
{
    Write-Verbose 'Calling SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST | SHCNF_FLUSH, NULL, NULL).';
    [PInvoke_23d32a02cf9c4b738171c5784dcf978b.Shell32]::SHChangeNotify(0x8000000, 0x1000, [System.UIntPtr]::Zero, [System.UIntPtr]::Zero);
    Write-Verbose 'SHChangeNotify returned.';
    Write-Verbose 'Finished ".pdf" thumbnail handler manipulation.';
}
