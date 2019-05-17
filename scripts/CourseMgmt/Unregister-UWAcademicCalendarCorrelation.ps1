[CmdletBinding(PositionalBinding = $False, SupportsShouldProcess = $True)]
Param
(
    [Parameter(Mandatory = $True)]
    [ValidatePattern('UW 20[0-9]{2}-20[0-9]{2} (Spring|Summer|Summer A|Summer B|Autumn|Winter)', Options='Compiled')]
    [string]$Term,
    [Parameter(Mandatory = $False)]
    [object]$OutlookFolder
)

Begin
{
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
    $found = $OutlookFolder.Items.Restrict("[CourseMgmtCorrId] = '$Term'") | Write-Output
    Write-Verbose "Found $($found.Count) events to unregister correlation."
    $action = 'Disassociate with ' + $Term
    $found | ForEach-Object {
        If ($PSCmdlet.ShouldProcess($_.Subject, $action))
        {
            $_.UserProperties['CourseMgmtCorrId'].Delete(); $_.Save();
        }
    } | Out-Null
}
