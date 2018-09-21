[CmdletBinding(PositionalBinding = $False)]
Param
(
    [Parameter(Mandatory = $True)]
    [object]$Target,
    [Parameter(Mandatory = $False)]
    [object]$OutlookFolder
)

Begin
{
    If ($Target.CorrId -eq $null)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new('Target is not published.'),
            'TargetNotPublished',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Target
        ))
    }

    If ($OutlookFolder -eq $null)
    {
        $selectFolderScript = [System.IO.Path]::Combine($PSScriptRoot, 'Select-OutlookFolder.ps1')
        $OutlookFolder = & $selectFolderScript
    }

    If ($OutlookFolder -eq $null)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentNullException]::new('OutlookFolder'),
            'OutlookFolderNull',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $null
        ))
    }

    $olAppointmentItem = 1
    $olFree = 0
    If ($OutlookFolder.DefaultItemType -ne $olAppointmentItem)
    {
        $PSCmdlet.ThrowTerminatingError([System.Management.Automation.ErrorRecord]::new(
            [System.ArgumentException]::new('OutlookFolder is not a calendar folder.', 'OutlookFolder'),
            'OutlookFolderNotCalendar',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $OutlookFolder
        ))
    }
}

Process
{
    $found = $OutlookFolder.Items.Restrict("[CourseMgmtCorrId] = '$($Target.CorrId)'") | Write-Output
    $found | ForEach-Object { $_.UserProperties['CourseMgmtCorrId'].Delete(); $_.Save(); } | Out-Null
}

End
{
    $Target
}
